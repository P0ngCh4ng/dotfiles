;;; pr-review-overlay.el --- Show the review target's changes in real buffers -*- lexical-binding: t; -*-

;;; Commentary:
;; pr-review で選んだ対象(FROM..TO)の変更箇所を、実際のファイルバッファ上に重ねて表示する。
;; helm から飛んでも、lsp で定義へ飛んでも、find-file で開いても同じように見える。
;;
;;   - 追加/変更行: 背景色 + fringe のバー
;;   - 削除のみの位置: fringe の三角マーク
;;   - `pr-review-next-change' / `pr-review-previous-change':
;;       変更箇所を順に巡回(ファイル末尾まで来たら次の変更ファイルへ)
;;       実行後は n / p / o だけで続けて操作できる
;;   - `pr-review-toggle-original': カーソル位置の変更箇所の「変更前」を赤字で差し込み表示
;;
;; ハイライトは TO 時点の内容のバッファにだけ付ける(行番号がずれないように):
;;   作業ツリーのファイルが TO と同じならそのファイル、違えば magit の TO 版バッファ。

;;; Code:

(require 'cl-lib)
(require 'subr-x)

;; pr-review.el が本ファイルを require するので、逆方向は declare のみ
(defvar pr-review--target-cache)
(declare-function pr-review--git "pr-review" (&rest args))
(declare-function pr-review--diff "pr-review" (&rest args))
(declare-function pr-review--diff-header-path "pr-review" (spec))
(declare-function pr-review--changed-since-p "pr-review" (rev file))
(declare-function pr-review--goto "pr-review" (root loc rev))
(declare-function pr-review--root "pr-review" ())

(defcustom pr-review-skip-files-regexp
  (rx (or "package-lock.json" "yarn.lock" "pnpm-lock.yaml" "bun.lockb" "bun.lock"
          "composer.lock" "Cargo.lock" "Gemfile.lock" "poetry.lock" "uv.lock" "go.sum")
      eos)
  "Files matching this regexp are skipped by change navigation and line search.
They still appear in the file list and are highlighted when opened."
  :type '(choice (const :tag "Skip nothing" nil) regexp)
  :group 'pr-review)

(defun pr-review--skip-file-p (file)
  "Return non-nil if FILE should be skipped by navigation and line search."
  (and pr-review-skip-files-regexp (string-match-p pr-review-skip-files-regexp file)))

(defface pr-review-added
  '((((class color) (background light)) :background "#ddffdd" :extend t)
    (((class color) (background dark)) :background "#1f3a24" :extend t))
  "Face for lines added or modified by the review target.")

(defface pr-review-removed
  '((((class color) (background light)) :background "#ffdddd" :foreground "#8b0000" :extend t)
    (((class color) (background dark)) :background "#4a1f22" :foreground "#ffb3b3" :extend t))
  "Face for original (removed) lines shown by `pr-review-toggle-original'.")

(defface pr-review-fringe-added
  '((t :foreground "#2ea043"))
  "Fringe face for added or modified lines.")

(defface pr-review-fringe-removed
  '((t :foreground "#cf222e"))
  "Fringe face for positions where lines were only removed.")

(defvar pr-review--hunk-cache (make-hash-table :test #'equal)
  "(ROOT FROM TO) → ((FILE . HUNKS) ...) in diff order.")

(defvar-local pr-review--buffer-hunks nil
  "Hunks highlighted in the current buffer, or nil.")

;;; ---------------------------------------------------------------------------
;;; Hunks: (:line L :start S :count C :old-count OC :removed (TEXT ...))
;;; ---------------------------------------------------------------------------

(defun pr-review--make-hunk (start count old-count removed)
  "Build a hunk plist.  :line is where the hunk shows in the new file."
  (list :line (if (zerop count) (1+ start) start)
        :start start :count count :old-count old-count
        :removed (nreverse removed)))

(defun pr-review--parse-hunks (diff-output)
  "Parse `git diff -U0' DIFF-OUTPUT into ((FILE . HUNKS) ...) in diff order.
Deleted files (no new side) are omitted."
  (let (files file hunks hunk-args removed prev)
    (cl-flet ((close-hunk ()
                (when hunk-args
                  (push (apply #'pr-review--make-hunk
                               (append hunk-args (list removed)))
                        hunks)
                  (setq hunk-args nil removed nil)))
              (close-file ()
                (when (and file hunks) (push (cons file (nreverse hunks)) files))
                (setq hunks nil)))
      (dolist (l (split-string diff-output "\n"))
        (cond
         ;; ファイル境界で hunk を閉じる(次の "--- a/..." を削除行と誤認しないように)
         ((string-prefix-p "diff --git " l)
          (close-hunk) (close-file) (setq file nil))
         ((and (string-prefix-p "+++ " l) prev (string-prefix-p "--- " prev))
          (close-hunk) (close-file)
          (setq file (pr-review--diff-header-path (substring l 4))))
         ((string-match "^@@ -[0-9]+\\(?:,\\([0-9]+\\)\\)? \\+\\([0-9]+\\)\\(?:,\\([0-9]+\\)\\)? @@" l)
          (close-hunk)
          (setq hunk-args
                (list (string-to-number (match-string 2 l))
                      (if (match-string 3 l) (string-to-number (match-string 3 l)) 1)
                      (if (match-string 1 l) (string-to-number (match-string 1 l)) 1))))
         ((and hunk-args (string-prefix-p "-" l))
          (push (substring l 1) removed)))
        (setq prev l))
      (close-hunk) (close-file))
    (nreverse files)))

(defun pr-review--target-hunks (from to)
  "Return ((FILE . HUNKS) ...) for FROM..TO in `default-directory' (cached).
A failed diff is cached as no changes so `find-file' doesn't retry it each time."
  (let ((key (list default-directory from to)))
    (pcase (gethash key pr-review--hunk-cache 'missing)
      ('missing
       (puthash key
                (condition-case err
                    (pr-review--parse-hunks (pr-review--diff "-U0" from to))
                  (error (message "pr-review: %s" (error-message-string err)) nil))
                pr-review--hunk-cache))
      (hunks hunks))))

;;; ---------------------------------------------------------------------------
;;; Which target/file does the current buffer show?
;;; ---------------------------------------------------------------------------

(defun pr-review--root-for (abs)
  "Return the target repository root containing ABS (the innermost one), or nil."
  (car (sort (cl-remove-if-not (lambda (r) (string-prefix-p r abs))
                               (hash-table-keys pr-review--target-cache))
             (lambda (a b) (> (length a) (length b))))))

(defun pr-review--blob-revision ()
  "Return the commit a magit blob buffer shows (var names vary by version)."
  (cl-some (lambda (v) (and (boundp v) (symbol-value v)))
           '(magit-buffer-revision-oid magit-buffer-revision-hash magit-buffer-revision)))

(defun pr-review--buffer-context ()
  "Return (ROOT TARGET FILE) if the buffer shows a target's file as of TO.
FILE is relative to ROOT.  Returns nil otherwise."
  (when-let* ((abs (or (and (boundp 'magit-buffer-file-name) magit-buffer-file-name)
                       buffer-file-name))
              (abs (file-truename abs))
              (root (pr-review--root-for abs))
              (target (gethash root pr-review--target-cache))
              (to (plist-get target :to))
              (file (file-relative-name abs root)))
    (let ((default-directory root))
      (when (and (assoc file (pr-review--target-hunks (plist-get target :from) to))
                 (if (bound-and-true-p magit-buffer-file-name)
                     (equal (pr-review--blob-revision) to)
                   (not (pr-review--changed-since-p to file))))
        (list root target file)))))

;;; ---------------------------------------------------------------------------
;;; Overlays
;;; ---------------------------------------------------------------------------

(defun pr-review--fringe (bitmap face)
  "Return a before-string that draws BITMAP with FACE in the left fringe."
  (propertize " " 'display `(left-fringe ,bitmap ,face)))

(defun pr-review--line-pos (line)
  "Return the position of the beginning of LINE (clamped to the buffer)."
  (save-excursion
    (goto-char (point-min))
    (forward-line (1- (max 1 line)))
    (point)))

(defun pr-review--add-hunk-overlay (hunk)
  "Create the overlay for HUNK in the current buffer."
  (let* ((count (plist-get hunk :count))
         (beg (pr-review--line-pos (plist-get hunk :line)))
         (end (if (zerop count) beg (pr-review--line-pos (+ (plist-get hunk :start) count))))
         (ov (make-overlay beg end nil t nil)))
    (overlay-put ov 'pr-review hunk)
    (overlay-put ov 'priority 10)
    (if (zerop count)
        (overlay-put ov 'before-string
                     (pr-review--fringe 'right-triangle 'pr-review-fringe-removed))
      (overlay-put ov 'face 'pr-review-added)
      ;; fringe のバーは行ごとの幅ゼロ overlay で描く(before-string は1行目にしか出ないため)
      (save-excursion
        (goto-char beg)
        (while (< (point) end)
          (let ((f (make-overlay (point) (point))))
            (overlay-put f 'pr-review-mark t)
            (overlay-put f 'before-string
                         (pr-review--fringe 'vertical-bar 'pr-review-fringe-added)))
          (forward-line 1))))
    ov))

(defun pr-review-overlay-clear ()
  "Remove pr-review overlays from the current buffer."
  (save-restriction
    (widen)
    (dolist (ov (overlays-in (point-min) (point-max)))
      (when (or (overlay-get ov 'pr-review)
                (overlay-get ov 'pr-review-mark)
                (overlay-get ov 'pr-review-for))
        (delete-overlay ov))))
  (setq pr-review--buffer-hunks nil))

(defun pr-review-overlay-apply ()
  "Highlight the review target's changes in the current buffer, if any."
  (pr-review-overlay-clear)
  (when (and (> (hash-table-count pr-review--target-cache) 0)
             (or buffer-file-name (bound-and-true-p magit-buffer-file-name)))
    ;; find-file-hook の他の関数(lsp など)を巻き込まないよう、エラーはここで止める
    (condition-case err
        (when-let* ((ctx (pr-review--buffer-context)))
          (pcase-let* ((`(,root ,target ,file) ctx)
                       (hunks (let ((default-directory root))
                                (cdr (assoc file (pr-review--target-hunks
                                                  (plist-get target :from)
                                                  (plist-get target :to)))))))
            (save-restriction
              (widen)
              (mapc #'pr-review--add-hunk-overlay hunks))
            (setq pr-review--buffer-hunks hunks)
            ;; 編集して保存したら TO と一致するか判定し直す(一致しなければ消える)
            (add-hook 'after-save-hook #'pr-review-overlay-apply nil t)))
      (error (message "pr-review: highlight failed: %s" (error-message-string err))))))

(defun pr-review-overlay-refresh-all ()
  "Re-apply highlighting in every file buffer (after the target changed)."
  (dolist (buf (buffer-list))
    (with-current-buffer buf
      (when (or buffer-file-name (bound-and-true-p magit-buffer-file-name))
        (pr-review-overlay-apply)))))

(add-hook 'find-file-hook #'pr-review-overlay-apply)
;; magit の blob バッファ用 hook は版によって名前が違う
(with-eval-after-load 'magit-files
  (add-hook (if (boundp 'magit-find-blob-hook) 'magit-find-blob-hook 'magit-find-file-hook)
            #'pr-review-overlay-apply))

;;; ---------------------------------------------------------------------------
;;; Navigation
;;; ---------------------------------------------------------------------------

(defvar pr-review-change-repeat-map
  (let ((map (make-sparse-keymap)))
    (define-key map "n" #'pr-review-next-change)
    (define-key map "p" #'pr-review-previous-change)
    (define-key map "o" #'pr-review-toggle-original)
    (define-key map "j" #'pr-review-next-file)
    map)
  "Keys that stay active right after a pr-review change command.")

(defun pr-review--all-changes (target)
  "Return a flat list ((FILE . HUNK) ...) of TARGET's changes in diff order."
  (cl-loop for (file . hunks) in (pr-review--target-hunks (plist-get target :from)
                                                         (plist-get target :to))
           unless (pr-review--skip-file-p file)
           append (mapcar (lambda (h) (cons file h)) hunks)))

(defun pr-review--current-position (root)
  "Return (FILE . LINE) for point if the buffer shows a file under ROOT, else nil."
  (when-let* ((abs (or (bound-and-true-p magit-buffer-file-name) buffer-file-name))
              (abs (file-truename abs))
              ((string-prefix-p root abs)))
    (cons (file-relative-name abs root) (line-number-at-pos nil t))))

(defun pr-review--change-index (changes pos forward)
  "Return the index in CHANGES of the change after POS.
Search backward (the change before POS) unless FORWARD."
  (let* ((files (delete-dups (mapcar #'car changes)))
         (rank (lambda (c) (list (cl-position (car c) files :test #'equal)
                                 (plist-get (cdr c) :line))))
         (here (and pos (list (or (cl-position (car pos) files :test #'equal) -1)
                              (cdr pos))))
         (less (lambda (a b) (or (< (car a) (car b))
                                 (and (= (car a) (car b)) (< (cadr a) (cadr b)))))))
    (cond
     ((or (null here) (< (car here) 0)) (if forward 0 (1- (length changes))))
     (forward (cl-position-if (lambda (c) (funcall less here (funcall rank c))) changes))
     (t (cl-position-if (lambda (c) (funcall less (funcall rank c) here)) changes
                        :from-end t)))))

(defun pr-review--move-change (forward)
  "Jump to the next (FORWARD) or previous change of the current repo's target."
  (let* ((root (pr-review--root))
         (default-directory root)
         (target (or (gethash root pr-review--target-cache)
                     (user-error "pr-review: No target; run C-c v v first")))
         (changes (or (pr-review--all-changes target)
                      (user-error "pr-review: Target has no textual changes")))
         (idx (pr-review--change-index changes (pr-review--current-position root) forward)))
    (unless idx
      (set-transient-map pr-review-change-repeat-map)
      (user-error "pr-review: No %s change" (if forward "next" "previous")))
    (pcase-let ((`(,file . ,hunk) (nth idx changes)))
      (pr-review--goto root (cons file (plist-get hunk :line)) (plist-get target :to))
      (message "pr-review [%d/%d] %s:%d  +%d -%d   (n/p: move, o: original, j: next file)"
               (1+ idx) (length changes) file (plist-get hunk :line)
               (plist-get hunk :count) (plist-get hunk :old-count))))
  (set-transient-map pr-review-change-repeat-map))

;;;###autoload
(defun pr-review-next-change ()
  "Jump to the next change of the review target, crossing files."
  (interactive)
  (pr-review--move-change t))

;;;###autoload
(defun pr-review-previous-change ()
  "Jump to the previous change of the review target, crossing files."
  (interactive)
  (pr-review--move-change nil))

;;; ---------------------------------------------------------------------------
;;; Viewed files ("このファイルはOK") and file-level navigation
;;; ---------------------------------------------------------------------------

(defvar pr-review--viewed (make-hash-table :test #'equal)
  "(ROOT FROM TO) → list of files marked as viewed.")

(defun pr-review--viewed-p (root from to file)
  "Return non-nil if FILE is marked as viewed for FROM..TO of ROOT."
  (member file (gethash (list root from to) pr-review--viewed)))

(defun pr-review--set-viewed (root from to file flag)
  "Mark FILE as viewed for FROM..TO of ROOT if FLAG, else unmark it."
  (let* ((key (list root from to))
         (others (remove file (gethash key pr-review--viewed))))
    (puthash key (if flag (cons file others) others) pr-review--viewed)))

(defun pr-review--review-files (from to)
  "Files of FROM..TO that change navigation visits, in diff order."
  (cl-remove-if #'pr-review--skip-file-p
                (mapcar #'car (pr-review--target-hunks from to))))

(defun pr-review--first-change-line (from to file)
  "Return the line of FILE's first change in FROM..TO (1 if none)."
  (or (plist-get (cadr (assoc file (pr-review--target-hunks from to))) :line) 1))

;;;###autoload
(defun pr-review-next-file ()
  "Mark the current file as viewed and go to the next file not yet viewed.
Files are visited in diff order, wrapping around."
  (interactive)
  (let* ((root (pr-review--root))
         (default-directory root)
         (target (or (gethash root pr-review--target-cache)
                     (user-error "pr-review: No target; run C-c v v first")))
         (from (plist-get target :from))
         (to (plist-get target :to))
         (files (or (pr-review--review-files from to)
                    (user-error "pr-review: Target has no textual changes")))
         (current (car (pr-review--current-position root)))
         (idx (or (cl-position current files :test #'equal) -1)))
    (when (member current files)
      (pr-review--set-viewed root from to current t))
    ;; 現在のファイルの次から一周して、未確認の最初のファイルを探す
    (let ((next (cl-find-if-not (lambda (f) (pr-review--viewed-p root from to f))
                                (append (nthcdr (1+ idx) files)
                                        (cl-subseq files 0 (max idx 0)))))
          (viewed (cl-count-if (lambda (f) (pr-review--viewed-p root from to f)) files)))
      (if (null next)
          (message "pr-review: All %d files viewed 🎉 (C-c v f: file list, C-c v u: back up)"
                   (length files))
        (pr-review--goto root (cons next (pr-review--first-change-line from to next)) to)
        (message "pr-review file %d/%d (%d viewed) %s   (j: next file, n/p: change)"
                 (1+ (cl-position next files :test #'equal)) (length files) viewed next))))
  (set-transient-map pr-review-change-repeat-map))

;;; ---------------------------------------------------------------------------
;;; Original (removed) lines
;;; ---------------------------------------------------------------------------

(defun pr-review--hunk-overlay-at-point ()
  "Return the hunk overlay covering point's line, or nil."
  (cl-find-if (lambda (ov) (overlay-get ov 'pr-review))
              (overlays-in (line-beginning-position)
                           (min (point-max) (1+ (line-end-position))))))

;;;###autoload
(defun pr-review-toggle-original ()
  "Show or hide the original (removed) lines of the change at point."
  (interactive)
  (let* ((ov (or (pr-review--hunk-overlay-at-point)
                 (user-error "pr-review: No change on this line")))
         (hunk (overlay-get ov 'pr-review))
         (shown (cl-find-if (lambda (o) (eq (overlay-get o 'pr-review-for) ov))
                            (overlays-in (overlay-start ov) (overlay-start ov)))))
    (cond
     (shown (delete-overlay shown))
     ((null (plist-get hunk :removed))
      (message "pr-review: Pure addition (nothing removed)"))
     (t
      (let ((o (make-overlay (overlay-start ov) (overlay-start ov))))
        (overlay-put o 'pr-review-for ov)
        (overlay-put o 'before-string
                     (mapconcat (lambda (l) (propertize (concat l "\n") 'face 'pr-review-removed))
                                (plist-get hunk :removed) ""))))))
  (set-transient-map pr-review-change-repeat-map))

(provide 'pr-review-overlay)
;;; pr-review-overlay.el ends here
