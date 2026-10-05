;;; pr-review.el --- Search only within the current PR's changes -*- lexical-binding: t; -*-

;;; Commentary:
;; AIが書いたPRをレビューするとき、プロジェクト全体ではなく
;; 「このPRで変わった部分」だけを対象に探すためのコマンド群。
;;
;; 比較範囲: merge-base(ベースブランチ, HEAD) → 作業ツリー
;;   - コミット済みの変更 + 未コミットの変更
;;   - 未追跡ファイルも含めたい場合は `pr-review-include-untracked' を t に
;;   - ベースブランチは gh pr view の baseRefName → origin/HEAD → main/master の順に推定
;;   - 推定結果はリポジトリごとにキャッシュ。`pr-review-set-base' で上書き可能
;;
;; コマンド (init.el で C-c v プレフィックスに割り当て):
;;   pr-review-search-changes  変更された行(追加/修正行)だけを絞り込み検索 → ジャンプ
;;   pr-review-find-file       変更されたファイルだけを選んで開く
;;   pr-review-grep            変更されたファイル全体を git grep
;;   pr-review-show-diff       PR全体の差分を magit で表示
;;   pr-review-commits         PR内のコミットを選び、そのコミットの変更行/ファイル/差分を確認
;;   pr-review-set-base        ベースブランチを手動指定 / キャッシュ再計算

;;; Code:

(require 'cl-lib)
(require 'subr-x)
(require 'helm)

(declare-function magit-diff-working-tree "magit-diff" (&optional rev args files))
(declare-function magit-show-commit "magit-diff" (rev &optional args files module))
(declare-function magit-find-file "magit-files" (rev file))
(declare-function magit-commit-at-point "magit-git" ())

(defgroup pr-review nil
  "Search within the current PR's changes."
  :group 'tools)

(defcustom pr-review-remote "origin"
  "Remote that hosts the PR's base branch."
  :type 'string)

(defcustom pr-review-include-untracked nil
  "Non-nil means untracked (not yet `git add'ed) files count as PR changes.
Off by default: untracked files often include build artifacts and caches."
  :type 'boolean)

(defvar pr-review--base-cache (make-hash-table :test #'equal)
  "Repository root → base ref (e.g. \"origin/main\").")

;;; ---------------------------------------------------------------------------
;;; git helpers
;;; ---------------------------------------------------------------------------

(defun pr-review--git (&rest args)
  "Run git with ARGS in `default-directory'.
Return (EXIT-CODE . OUTPUT)."
  (with-temp-buffer
    (let ((code (apply #'process-file "git" nil t nil
                       "-c" "core.quotepath=false" args)))
      (cons code (buffer-string)))))

(defun pr-review--git-string (&rest args)
  "Run git with ARGS and return trimmed stdout, or nil on failure."
  (pcase-let ((`(,code . ,out) (apply #'pr-review--git args)))
    (when (zerop code) (string-trim out))))

(defun pr-review--root ()
  "Return the git repository root of `default-directory' or signal an error."
  (let ((root (pr-review--git-string "rev-parse" "--show-toplevel")))
    (unless root (user-error "pr-review: Not inside a git repository"))
    (file-name-as-directory root)))

(defun pr-review--ref-exists-p (ref)
  "Return non-nil if REF resolves to a commit."
  (pr-review--git-string "rev-parse" "--verify" "--quiet" (concat ref "^{commit}")))

(defun pr-review--gh-base-branch ()
  "Return the base branch name of the PR for HEAD via gh, or nil."
  (when (executable-find "gh")
    (with-temp-buffer
      (when (zerop (process-file "gh" nil '(t nil) nil
                                 "pr" "view" "--json" "baseRefName"
                                 "--jq" ".baseRefName"))
        (let ((name (string-trim (buffer-string))))
          (unless (string-empty-p name) name))))))

(defun pr-review--detect-base ()
  "Guess the base ref for the current branch."
  (let* ((remote-head (pr-review--git-string
                       "symbolic-ref" "--quiet" "--short"
                       (format "refs/remotes/%s/HEAD" pr-review-remote)))
         (gh-branch (pr-review--gh-base-branch))
         (candidates (delq nil
                           (list (and gh-branch (format "%s/%s" pr-review-remote gh-branch))
                                 gh-branch
                                 remote-head
                                 (format "%s/main" pr-review-remote)
                                 (format "%s/master" pr-review-remote)
                                 "main" "master"))))
    ;; origin/HEAD がPR作業ブランチを指していて main と履歴が繋がっていない
    ;; リポジトリもあるため、HEAD と共通祖先を持つ候補だけを採用する
    (or (cl-find-if (lambda (ref)
                      (and (pr-review--ref-exists-p ref)
                           (pr-review--git-string "merge-base" ref "HEAD")))
                    candidates)
        (user-error "pr-review: Could not detect base branch; run M-x pr-review-set-base"))))

(defun pr-review--base (root)
  "Return the (cached) base ref for repository ROOT."
  (or (gethash root pr-review--base-cache)
      (puthash root (pr-review--detect-base) pr-review--base-cache)))

(defun pr-review--merge-base (root)
  "Return the merge-base commit between HEAD and the base ref of ROOT."
  (let ((base (pr-review--base root)))
    (or (pr-review--git-string "merge-base" base "HEAD")
        ;; キャッシュが古い(ブランチ切替・ref削除など)場合は一度だけ再推定
        (let ((fresh (progn (remhash root pr-review--base-cache)
                            (pr-review--base root))))
          (pr-review--git-string "merge-base" fresh "HEAD"))
        (user-error "pr-review: No merge-base between %s and HEAD; run M-x pr-review-set-base"
                    base))))

(defun pr-review--untracked-files ()
  "Return untracked, non-ignored files relative to the repository root."
  (when pr-review-include-untracked
    (split-string (or (pr-review--git-string "ls-files" "--others" "--exclude-standard")
                      "")
                  "\n" t)))

(defun pr-review--changed-files (merge-base)
  "Return files changed since MERGE-BASE, excluding deleted ones.
Each element is (STATUS . PATH) with paths relative to the repository root."
  (let* ((out (or (pr-review--git-string "diff" "--name-status" "--no-renames"
                                         "--diff-filter=d" merge-base)
                  (user-error "pr-review: git diff failed")))
         (tracked (mapcar (lambda (line)
                            (let ((cols (split-string line "\t")))
                              (cons (car cols) (cadr cols))))
                          (split-string out "\n" t))))
    (append tracked
            (mapcar (lambda (f) (cons "?" f)) (pr-review--untracked-files)))))

(defmacro pr-review--with-context (vars &rest body)
  "Bind VARS = (ROOT MERGE-BASE) for the current repo and run BODY there."
  (declare (indent 1))
  (let ((root (car vars)) (mb (cadr vars)))
    `(let* ((,root (pr-review--root))
            (default-directory ,root)
            (,mb (pr-review--merge-base ,root)))
       ,@body)))

;;; ---------------------------------------------------------------------------
;;; Jump helpers
;;; ---------------------------------------------------------------------------

(defun pr-review--changed-since-p (rev file)
  "Return non-nil if FILE in the working tree differs from its state at REV."
  (not (zerop (car (pr-review--git "diff" "--quiet" rev "--" file)))))

(defun pr-review--goto (root loc &optional rev)
  "Open file of LOC = (FILE . LINE) under ROOT and move to LINE.
LINE refers to the file as of REV when REV is given.  If the file was
changed after REV, open REV's version (read-only) so LINE stays exact;
otherwise open the working-tree file so lsp etc. work as usual."
  (let ((default-directory root)
        (file (car loc)))
    (if (and rev (pr-review--changed-since-p rev file))
        (progn
          (require 'magit)
          (magit-find-file rev file)
          (message "pr-review: %s changed after %s; showing that revision (read-only)"
                   file rev))
      (find-file (expand-file-name file root))))
  (goto-char (point-min))
  (forward-line (1- (cdr loc)))
  (recenter))

(defun pr-review--format (file line text)
  "Format a helm candidate display string for FILE, LINE and TEXT."
  (format "%s:%s: %s"
          (propertize file 'face 'helm-grep-file)
          (propertize (number-to-string line) 'face 'helm-grep-lineno)
          text))

(defun pr-review--helm-locations (title root candidates &optional rev)
  "Show CANDIDATES ((DISPLAY . (FILE . LINE)) ...) in helm under TITLE.
REV is passed to `pr-review--goto'."
  (unless candidates (user-error "pr-review: No matches"))
  (helm :sources (helm-build-sync-source title
                   :candidates candidates
                   :candidate-number-limit 10000
                   :action (lambda (loc) (pr-review--goto root loc rev))
                   :persistent-action (lambda (loc) (pr-review--goto root loc rev))
                   :persistent-help "Preview")
        :buffer "*helm pr-review*"))

;;; ---------------------------------------------------------------------------
;;; Search changed lines
;;; ---------------------------------------------------------------------------

(defun pr-review--parse-added-lines (diff-output)
  "Parse `git diff -U0' DIFF-OUTPUT into ((FILE LINE TEXT) ...) for added lines."
  (let (file line result)
    (dolist (l (split-string diff-output "\n"))
      (cond
       ((string-prefix-p "+++ " l)
        (setq file (and (string-prefix-p "+++ b/" l) (substring l 6))))
       ((string-match "^@@ -[0-9,]+ \\+\\([0-9]+\\)" l)
        (setq line (string-to-number (match-string 1 l))))
       ((and file line (string-prefix-p "+" l))
        (push (list file line (substring l 1)) result)
        (cl-incf line))))
    (nreverse result)))

(defun pr-review--line-candidates (lines)
  "Turn LINES ((FILE LINE TEXT) ...) into helm location candidates."
  (cl-loop for (file line text) in lines
           unless (string-blank-p text)
           collect (cons (pr-review--format file line text) (cons file line))))

(defun pr-review--untracked-lines ()
  "Return ((FILE LINE TEXT) ...) for every line of untracked text files."
  (cl-loop for file in (pr-review--untracked-files)
           when (and (file-regular-p file)
                     (< (file-attribute-size (file-attributes file)) (* 1024 1024)))
           append (with-temp-buffer
                    (insert-file-contents file)
                    (unless (search-forward "\0" nil t) ; skip binaries
                      (cl-loop for text in (split-string (buffer-string) "\n")
                               for n from 1
                               collect (list file n text))))))

;;;###autoload
(defun pr-review-search-changes ()
  "Narrow down lines added or modified in the current PR and jump to one."
  (interactive)
  (pr-review--with-context (root mb)
    (let* ((diff (pcase-let ((`(,code . ,out)
                              (pr-review--git "diff" "-U0" "--no-color" "--no-ext-diff"
                                              "--no-renames" mb)))
                   (unless (zerop code) (user-error "pr-review: git diff failed"))
                   out))
           (lines (append (pr-review--parse-added-lines diff)
                          (pr-review--untracked-lines))))
      (pr-review--helm-locations
       (format "PR changes (vs %s)" (pr-review--base root))
       root
       (pr-review--line-candidates lines)))))

;;; ---------------------------------------------------------------------------
;;; Changed files / grep / diff
;;; ---------------------------------------------------------------------------

;;;###autoload
(defun pr-review-find-file ()
  "Open one of the files changed in the current PR."
  (interactive)
  (pr-review--with-context (root mb)
    (let ((files (pr-review--changed-files mb)))
      (unless files (user-error "pr-review: No changed files"))
      (helm :sources (helm-build-sync-source
                         (format "PR files (vs %s)" (pr-review--base root))
                       :candidates (mapcar (lambda (sf)
                                             (cons (format "%s  %s" (car sf) (cdr sf))
                                                   (cdr sf)))
                                           files)
                       :candidate-number-limit 10000
                       :action (lambda (f) (find-file (expand-file-name f root))))
            :buffer "*helm pr-review files*"))))

;;;###autoload
(defun pr-review-grep (pattern)
  "Run git grep for PATTERN (extended regexp) in the files changed by the PR.
Unlike `pr-review-search-changes', this searches whole files, so
unchanged lines around the changes are included."
  (interactive
   (list (read-string (format-prompt "PR grep" (thing-at-point 'symbol t))
                      nil nil (thing-at-point 'symbol t))))
  (pr-review--with-context (root mb)
    (let ((files (mapcar #'cdr (pr-review--changed-files mb))))
      (unless files (user-error "pr-review: No changed files"))
      (pcase-let ((`(,code . ,out)
                   (apply #'pr-review--git "grep" "-n" "-I" "-E" "--no-color"
                          (append (and pr-review-include-untracked '("--untracked"))
                                  (list "-e" pattern "--")
                                  files))))
        (when (> code 1) (user-error "pr-review: git grep failed: %s" (string-trim out)))
        (pr-review--helm-locations
         (format "PR grep: %s" pattern)
         root
         (cl-loop for l in (split-string out "\n" t)
                  when (string-match "\\`\\([^:]+\\):\\([0-9]+\\):\\(.*\\)\\'" l)
                  collect (let ((file (match-string 1 l))
                                (line (string-to-number (match-string 2 l))))
                            (cons (pr-review--format file line (match-string 3 l))
                                  (cons file line)))))))))

;;;###autoload
(defun pr-review-show-diff ()
  "Show the whole PR diff (merge-base → working tree) in magit."
  (interactive)
  (require 'magit)
  (pr-review--with-context (root mb)
    (ignore root)
    (magit-diff-working-tree mb)))

;;; ---------------------------------------------------------------------------
;;; Per-commit review
;;; ---------------------------------------------------------------------------

(defun pr-review--diff-tree (hash &rest args)
  "Run git diff-tree for commit HASH with ARGS and return its output.
Merge commits are diffed against their first parent; root commits work too."
  (pcase-let ((`(,code . ,out)
               (apply #'pr-review--git "diff-tree" "-r" "--no-commit-id" "--no-color"
                      "--no-ext-diff" "--no-renames" "--root" "-m" "--first-parent"
                      (append args (list hash)))))
    (unless (zerop code) (user-error "pr-review: git diff-tree failed: %s" (string-trim out)))
    out))

(defun pr-review--commits (mb)
  "Return ((DISPLAY . HASH) ...) for commits in MB..HEAD, newest first."
  (cl-loop for l in (split-string (or (pr-review--git-string
                                       "log" "--no-color"
                                       "--format=%h%x09%s%x09%an%x09%ar"
                                       (concat mb "..HEAD"))
                                      "")
                                  "\n" t)
           for (hash subject author date) = (split-string l "\t")
           collect (cons (format "%s  %s  %s"
                                 (propertize hash 'face 'font-lock-constant-face)
                                 subject
                                 (propertize (format "(%s, %s)" author date) 'face 'shadow))
                         hash)))

(defun pr-review--search-commit (root hash)
  "Narrow down lines added or modified by commit HASH in ROOT."
  (let ((default-directory root))
    (pr-review--helm-locations
     (format "Commit %s changes" hash)
     root
     (pr-review--line-candidates
      (pr-review--parse-added-lines (pr-review--diff-tree hash "-p" "-U0")))
     hash)))

(defun pr-review--commit-files (root hash)
  "Open one of the files changed by commit HASH in ROOT."
  (let* ((default-directory root)
         (files (cl-loop for l in (split-string
                                   (pr-review--diff-tree hash "--name-status" "--diff-filter=d")
                                   "\n" t)
                         for (status file) = (split-string l "\t")
                         collect (cons (format "%s  %s" status file) file))))
    (unless files (user-error "pr-review: Commit %s changes no files" hash))
    (helm :sources (helm-build-sync-source (format "Commit %s files" hash)
                     :candidates files
                     :candidate-number-limit 10000
                     :action (lambda (f) (pr-review--goto root (cons f 1) hash)))
          :buffer "*helm pr-review files*")))

(defun pr-review--commit-preselect ()
  "Return a helm preselect regexp for the magit commit at point, or nil."
  (when-let* (((derived-mode-p 'magit-mode))
              (rev (magit-commit-at-point))
              (short (pr-review--git-string "rev-parse" "--short" rev)))
    (concat "^" (regexp-quote short))))

;;;###autoload
(defun pr-review-commits ()
  "Pick a commit of the current PR and review only that commit.
In magit buffers the commit at point is preselected."
  (interactive)
  (pr-review--with-context (root mb)
    (let ((commits (pr-review--commits mb)))
      (unless commits (user-error "pr-review: No commits since %s" (pr-review--base root)))
      (helm :sources (helm-build-sync-source
                         (format "PR commits (vs %s)" (pr-review--base root))
                       :candidates commits
                       :candidate-number-limit 10000
                       :action `(("Search changed lines" .
                                  ,(lambda (h) (pr-review--search-commit root h)))
                                 ("Open changed file" .
                                  ,(lambda (h) (pr-review--commit-files root h)))
                                 ("Show commit diff (magit)" .
                                  ,(lambda (h) (require 'magit) (magit-show-commit h)))))
            :preselect (pr-review--commit-preselect)
            :buffer "*helm pr-review commits*"))))

;;;###autoload
(defun pr-review-set-base (base)
  "Set the base ref of the current repository to BASE.
With an empty input, forget the cached value and auto-detect again."
  (interactive
   (list (read-string "Base ref (empty = auto-detect): "
                      (format "%s/" pr-review-remote))))
  (let ((root (pr-review--root)))
    (if (or (string-empty-p base) (string= base (format "%s/" pr-review-remote)))
        (progn (remhash root pr-review--base-cache)
               (message "pr-review: base = %s" (pr-review--base root)))
      (let ((default-directory root))
        (unless (pr-review--ref-exists-p base)
          (user-error "pr-review: Unknown ref %s (git fetch?)" base)))
      (puthash root base pr-review--base-cache)
      (message "pr-review: base = %s" base))))

(provide 'pr-review)
;;; pr-review.el ends here
