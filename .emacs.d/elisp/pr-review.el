;;; pr-review.el --- Search only within a chosen PR or commit -*- lexical-binding: t; -*-

;;; Commentary:
;; AIが書いたPRをレビューするとき、プロジェクト全体ではなく
;; 「選んだPR / コミットで変わった部分」だけを対象に探すためのコマンド群。
;;
;; HEAD や作業ツリーの状態には依存しない:
;;   1. `pr-review-select' で直近のPR(open/merged/closed)かコミットを一覧から選ぶ
;;   2. 以降のコマンドはその差分(FROM..TO)だけを対象にする
;;   - 対象はリポジトリごとに記憶。未選択でコマンドを実行すると選択から始まる
;;   - PR は gh pr list から取得。未マージPRは refs/pull/N/head を fetch して
;;     merge-base(ベース, head)..head を対象にする(GitHub の Files changed と同じ)
;;   - マージ済みPRはマージ方法を判定して範囲を決める
;;       マージコミット: M^1..M / squash: M^..M / rebase: M~K..M (K=PRのコミット数)
;;   - ファイルを開くときは TO 時点の内容。作業ツリーと同じならそのファイル、
;;     違えば TO 時点の版を読み取り専用で開く(行番号がずれないように)
;;
;; コマンド (init.el で C-c v プレフィックスに割り当て):
;;   pr-review-select          レビュー対象のPR/コミットを選ぶ
;;   pr-review-search-changes  変更された行(追加/修正行)だけを絞り込み検索 → ジャンプ
;;   pr-review-find-file       変更ファイル一覧(拠点): 確認済み✓の管理、今のファイルを選択済み
;;   pr-review-grep            変更されたファイル全体を git grep (TO 時点)
;;   pr-review-show-diff       対象の差分を magit で表示
;;   pr-review-commits         対象内のコミットを選び、対象をそのコミットに絞り込む
;;   pr-review-up              コミットの絞り込みから元の対象に戻る
;;   pr-review-clear           対象を解除してハイライトを消す
;;   pr-review-help            キー一覧・レビューの流れ・現在の対象を表示
;;
;; 変更箇所のハイライトと巡回(n/p/o)は pr-review-overlay.el を参照。

;;; Code:

(require 'cl-lib)
(require 'subr-x)
(require 'helm)
(require 'pr-review-overlay)

(declare-function magit-diff-range "magit-diff" (rev-or-range &optional args files))
(declare-function magit-show-commit "magit-diff" (rev &optional args files module))
(declare-function magit-find-file "magit-files" (rev file))
(declare-function magit-commit-at-point "magit-git" ())

(defgroup pr-review nil
  "Search within a chosen PR's or commit's changes."
  :group 'tools)

(defcustom pr-review-remote "origin"
  "Remote that hosts the PRs."
  :type 'string)

(defcustom pr-review-pr-limit 30
  "Number of recent PRs listed by `pr-review-select'."
  :type 'integer)

(defcustom pr-review-commit-limit 200
  "Number of recent commits listed by `pr-review-select'."
  :type 'integer)

(defconst pr-review--empty-tree "4b825dc642cb6eb9a060e54bf8d69288fbee4904"
  "Hash of git's empty tree, used as FROM for root commits.")

(defvar pr-review--target-cache (make-hash-table :test #'equal)
  "Repository root → selected target plist (:label :from :to).")

;;; ---------------------------------------------------------------------------
;;; git helpers
;;; ---------------------------------------------------------------------------

(defun pr-review--git (&rest args)
  "Run git with ARGS in `default-directory'.
Return (EXIT-CODE . OUTPUT)."
  (with-temp-buffer
    (let ((code (apply #'process-file "git" nil t nil
                       "-c" "core.quotepath=false" "--literal-pathspecs" args)))
      (cons code (buffer-string)))))

(defun pr-review--git-string (&rest args)
  "Run git with ARGS and return trimmed stdout, or nil on failure."
  (pcase-let ((`(,code . ,out) (apply #'pr-review--git args)))
    (when (zerop code) (string-trim out))))

(defun pr-review--git-lines (&rest args)
  "Run git with ARGS and return its stdout lines (nil on failure)."
  (split-string (or (apply #'pr-review--git-string args) "") "\n" t))

(defun pr-review--root ()
  "Return the git repository root of `default-directory' or signal an error."
  (let ((root (pr-review--git-string "rev-parse" "--show-toplevel")))
    (unless root (user-error "pr-review: Not inside a git repository"))
    (file-name-as-directory root)))

(defun pr-review--commit (rev)
  "Return the full hash REV resolves to, or nil."
  (pr-review--git-string "rev-parse" "--verify" "--quiet" (concat rev "^{commit}")))

(defun pr-review--fetch (&rest refspecs)
  "Fetch REFSPECS from `pr-review-remote'; return non-nil on success."
  (zerop (car (apply #'pr-review--git "fetch" "--quiet" pr-review-remote refspecs))))

;;; ---------------------------------------------------------------------------
;;; Targets: (:label LABEL :from FROM :to TO)
;;; ---------------------------------------------------------------------------

(defun pr-review--commit-target (hash)
  "Return the target for a single commit HASH (merges vs first parent)."
  (let ((to (or (pr-review--commit hash)
                (user-error "pr-review: Unknown commit %s" hash))))
    (list :label (format "commit %s %s"
                         (substring to 0 7)
                         (pr-review--git-string "log" "-1" "--format=%s" to))
          :from (or (pr-review--commit (concat to "^1")) pr-review--empty-tree)
          :to to)))

(defun pr-review--rebase-merged-p (merge headlines)
  "Return non-nil if MERGE ends a rebase of commits with HEADLINES (oldest first)."
  (equal (reverse (pr-review--git-lines "log" "--first-parent" "--no-merges" "--format=%s"
                                        "-n" (number-to-string (length headlines))
                                        merge))
         headlines))

(defun pr-review--merged-range (pr merge)
  "Return (FROM . TO) for merged PR whose merge commit is MERGE."
  (let ((parents (length (cdr (split-string
                               (pr-review--git-string "rev-list" "--parents" "-n1" merge)))))
        ;; rebase マージでは PR 内のマージコミットは捨てられるので比較から除外
        (headlines (cl-remove-if (lambda (h) (string-prefix-p "Merge " h))
                                 (mapcar (lambda (c) (alist-get 'messageHeadline c))
                                         (alist-get 'commits pr)))))
    (cons (cond ((>= parents 2) (concat merge "^1"))
                ((and (> (length headlines) 1)
                      (pr-review--rebase-merged-p merge headlines))
                 (format "%s~%d" merge (length headlines)))
                (t (concat merge "^1")))
          merge)))

(defun pr-review--open-range (pr)
  "Return (FROM . TO) for unmerged PR, like GitHub's Files changed tab."
  (let* ((number (alist-get 'number pr))
         (local (format "refs/pr-review/pull/%d" number))
         (base (alist-get 'baseRefName pr)))
    (unless (pr-review--fetch (format "+refs/pull/%d/head:%s" number local))
      (user-error "pr-review: Could not fetch PR #%d" number))
    (pr-review--fetch base)
    (let ((head (pr-review--commit local)))
      (cons (or (pr-review--git-string "merge-base"
                                       (format "%s/%s" pr-review-remote base) head)
                (user-error "pr-review: No merge-base between %s and PR #%d" base number))
            head))))

(defun pr-review--pr-target (pr)
  "Return the target for PR (an alist from gh)."
  (let* ((merge (alist-get 'oid (alist-get 'mergeCommit pr)))
         (range (if (and merge (equal (alist-get 'state pr) "MERGED"))
                    (progn
                      (unless (pr-review--commit merge)
                        (pr-review--fetch (alist-get 'baseRefName pr)))
                      (unless (pr-review--commit merge)
                        (user-error "pr-review: Merge commit %s not found (git fetch?)" merge))
                      (pr-review--merged-range pr merge))
                  (pr-review--open-range pr))))
    (list :label (format "PR #%d %s" (alist-get 'number pr) (alist-get 'title pr))
          :from (or (pr-review--commit (car range))
                    (user-error "pr-review: Cannot resolve %s (shallow clone?)" (car range)))
          :to (or (pr-review--commit (cdr range))
                  (user-error "pr-review: Cannot resolve %s" (cdr range))))))

;;; ---------------------------------------------------------------------------
;;; Target selection
;;; ---------------------------------------------------------------------------

(defun pr-review--fetch-prs ()
  "Return recent PRs of the current repository via gh, newest first."
  (unless (executable-find "gh") (user-error "pr-review: gh is not installed"))
  (with-temp-buffer
    (let ((code (process-file "gh" nil '(t nil) nil "pr" "list" "--state" "all"
                              "--limit" (number-to-string pr-review-pr-limit)
                              "--json" "number,title,state,author,headRefName,baseRefName,mergeCommit,commits")))
      (if (zerop code)
          (json-parse-string (buffer-string) :object-type 'alist :array-type 'list
                             :null-object nil :false-object nil)
        (message "pr-review: gh pr list failed; listing commits only")
        nil))))

(defun pr-review--pr-candidates (prs)
  "Turn PRS into helm candidates ((DISPLAY . PR) ...)."
  (mapcar (lambda (pr)
            (let ((state (alist-get 'state pr)))
              (cons (format "#%-4d %-6s  %s  %s"
                            (alist-get 'number pr)
                            (propertize state 'face (if (equal state "OPEN")
                                                        'success 'shadow))
                            (alist-get 'title pr)
                            (propertize (format "(%s → %s, %s)"
                                                (alist-get 'headRefName pr)
                                                (alist-get 'baseRefName pr)
                                                (or (alist-get 'login (alist-get 'author pr)) "?"))
                                        'face 'shadow))
                    pr)))
          prs))

(defun pr-review--commit-candidates ()
  "Return helm candidates ((DISPLAY . HASH) ...) for recent commits."
  (cl-loop for l in (pr-review--git-lines
                     "log" "--branches" "--remotes" "--tags" "--date-order" "--no-color"
                     "-n" (number-to-string pr-review-commit-limit)
                     "--format=%h%x09%s%x09%an%x09%ar%x09%D")
           for (hash subject author date refs) = (split-string l "\t")
           collect (cons (format "%s  %s  %s%s"
                                 (propertize hash 'face 'font-lock-constant-face)
                                 subject
                                 (propertize (format "(%s, %s)" author date) 'face 'shadow)
                                 (if (string-empty-p (or refs ""))
                                     ""
                                   (propertize (format " [%s]" refs) 'face 'font-lock-keyword-face)))
                         hash)))

(defun pr-review--commit-preselect ()
  "Return a helm preselect regexp for the magit commit at point, or nil."
  (when-let* (((derived-mode-p 'magit-mode))
              (rev (magit-commit-at-point))
              (short (pr-review--git-string "rev-parse" "--short" rev)))
    (concat "^" (regexp-quote short))))

;;;###autoload
(defun pr-review-select ()
  "Choose a recent PR or commit as the review target and return it.
In magit buffers the commit at point is preselected."
  (interactive)
  (let* ((root (pr-review--root))
         (default-directory root)
         (preselect (pr-review--commit-preselect))
         (target (helm :sources
                       (list (helm-build-sync-source "Pull requests"
                               :candidates (pr-review--pr-candidates (pr-review--fetch-prs))
                               :candidate-number-limit 10000
                               :action (lambda (pr)
                                         (let ((default-directory root))
                                           (pr-review--pr-target pr))))
                             (helm-build-sync-source "Commits"
                               :candidates (pr-review--commit-candidates)
                               :candidate-number-limit 10000
                               :action (lambda (h)
                                         (let ((default-directory root))
                                           (pr-review--commit-target h)))))
                       :preselect preselect
                       :buffer "*helm pr-review select*")))
    (unless target (user-error "pr-review: Nothing selected"))
    (puthash root target pr-review--target-cache)
    (pr-review-overlay-refresh-all)
    (message "pr-review: target = %s (%s..%s)" (plist-get target :label)
             (substring (plist-get target :from) 0 7) (substring (plist-get target :to) 0 7))
    target))

(defmacro pr-review--with-target (vars &rest body)
  "Bind VARS = (ROOT FROM TO LABEL) for the current repo's target and run BODY.
Prompts with `pr-review-select' when no target has been chosen yet."
  (declare (indent 1))
  (let ((target (make-symbol "target")))
    `(let* ((,(nth 0 vars) (pr-review--root))
            (default-directory ,(nth 0 vars))
            (,target (or (gethash ,(nth 0 vars) pr-review--target-cache)
                         (pr-review-select)))
            (,(nth 1 vars) (plist-get ,target :from))
            (,(nth 2 vars) (plist-get ,target :to))
            (,(nth 3 vars) (plist-get ,target :label)))
       (ignore ,(nth 1 vars) ,(nth 2 vars) ,(nth 3 vars))
       ,@body)))

;;; ---------------------------------------------------------------------------
;;; Jump helpers
;;; ---------------------------------------------------------------------------

(defun pr-review--changed-since-p (rev file)
  "Return non-nil if FILE in the working tree differs from its state at REV."
  (not (zerop (car (pr-review--git "diff" "--quiet" rev "--" file)))))

(defun pr-review--goto (root loc rev)
  "Open file of LOC = (FILE . LINE) under ROOT as of REV and move to LINE.
If the working-tree file differs from REV, open REV's version (read-only)
so LINE stays exact; otherwise open the working-tree file so lsp etc. work."
  (let ((default-directory root)
        (file (car loc)))
    (if (pr-review--changed-since-p rev file)
        (progn
          (require 'magit)
          (magit-find-file rev file)
          (message "pr-review: showing %s as of %s (read-only)" file (substring rev 0 7)))
      (find-file (expand-file-name file root))))
  ;; 既に開いていたバッファは find-file-hook が走らないので、ここでハイライト
  (unless pr-review--buffer-hunks (pr-review-overlay-apply))
  (goto-char (point-min))
  (forward-line (1- (cdr loc)))
  (recenter))

(defun pr-review--numstat (from to)
  "Return a hash table PATH → (ADDED . DELETED) for FROM..TO (binary: nil)."
  (let ((table (make-hash-table :test #'equal)))
    ;; -z --numstat: "ADDED\tDELETED\tPATH\0"
    (dolist (rec (split-string (pr-review--diff "-z" "--numstat" from to) "\0" t))
      (pcase-let ((`(,a ,d ,path) (split-string rec "\t")))
        (puthash path (and (not (equal a "-")) (cons a d)) table)))
    table))

(defun pr-review--file-stat (numstat path)
  "Format the +/- line counts of PATH from the NUMSTAT table."
  (let ((stat (gethash path numstat)))
    (if stat
        (concat (propertize (concat "+" (car stat)) 'face 'success) " "
                (propertize (concat "-" (cdr stat)) 'face 'error))
      (propertize "bin" 'face 'shadow))))

(defun pr-review--viewed-mark (root from to file)
  "Return a check mark if FILE is viewed for FROM..TO of ROOT, else a space."
  (if (pr-review--viewed-p root from to file) (propertize "✓" 'face 'success) " "))

(defun pr-review--helm-by-file (title root from to items)
  "Show ITEMS ((FILE LINE TEXT) ...) in helm, one section per file.
Each section header shows the file's +/- counts and viewed mark; C-o moves
to the next file.  Selecting a line opens the file as of TO at that line."
  (unless items (user-error "pr-review: No matches"))
  (let ((numstat (pr-review--numstat from to))
        (goto (lambda (loc) (pr-review--goto root loc to))))
    (helm :sources
          (mapcar (lambda (file)
                    (helm-build-sync-source
                        (format "%s %s  %s" (pr-review--viewed-mark root from to file)
                                file (pr-review--file-stat numstat file))
                      :candidates (cl-loop for (f line text) in items
                                           when (equal f file)
                                           collect (cons (format "%s: %s"
                                                                 (propertize (format "%5d" line)
                                                                             'face 'helm-grep-lineno)
                                                                 text)
                                                         (cons file line)))
                      :candidate-number-limit 10000
                      :action goto
                      :persistent-action goto
                      :persistent-help "Preview"))
                  (delete-dups (mapcar #'car items)))
          :prompt (format "%s: " title)
          :buffer "*helm pr-review*")))

;;; ---------------------------------------------------------------------------
;;; Diff parsing
;;; ---------------------------------------------------------------------------

(defun pr-review--diff (&rest args)
  "Run git diff with ARGS (plus common options) and return its output."
  (pcase-let ((`(,code . ,out)
               (apply #'pr-review--git "diff" "--no-color" "--no-ext-diff" "--no-renames"
                      "--src-prefix=a/" "--dst-prefix=b/" args)))
    (unless (zerop code) (user-error "pr-review: git diff failed: %s" (string-trim out)))
    out))

(defun pr-review--diff-header-path (spec)
  "Return the path from a diff header SPEC like b/foo or \"b/foo\", or nil."
  (let ((spec (string-remove-suffix "\t" spec)))
    (when (string-prefix-p "\"" spec)
      (setq spec (read spec)))           ; C-style quoted path
    (and (string-prefix-p "b/" spec) (substring spec 2))))

(defun pr-review--parse-added-lines (diff-output)
  "Parse `git diff -U0' DIFF-OUTPUT into ((FILE LINE TEXT) ...) for added lines."
  (let (file line prev result)
    (dolist (l (split-string diff-output "\n"))
      (cond
       ;; "+++" はファイルヘッダ("---" の直後)のときだけ。追加行 "++ x" と区別する
       ((and (string-prefix-p "+++ " l) prev (string-prefix-p "--- " prev))
        (setq line nil
              file (pr-review--diff-header-path (substring l 4))))
       ((string-match "^@@ -[0-9,]+ \\+\\([0-9]+\\)" l)
        (setq line (string-to-number (match-string 1 l))))
       ((and file line (string-prefix-p "+" l))
        (push (list file line (substring l 1)) result)
        (cl-incf line)))
      (setq prev l))
    (nreverse result)))

(defun pr-review--searchable-lines (lines)
  "Drop blank lines and skipped files (lock files etc.) from LINES."
  (cl-remove-if (pcase-lambda (`(,file ,_ ,text))
                  (or (string-blank-p text) (pr-review--skip-file-p file)))
                lines))

(defun pr-review--changed-files (from to)
  "Return ((STATUS . PATH) ...) for files changed in FROM..TO, excluding deletions."
  ;; -z: "STATUS\0PATH\0..." (特殊文字を含むパスも引用符なしで得る)
  (cl-loop for (status path) on (split-string
                                 (pr-review--diff "-z" "--name-status" "--diff-filter=d" from to)
                                 "\0" t)
           by #'cddr
           collect (cons status path)))

(defun pr-review--search-range (root label from to)
  "Narrow down lines added or modified in FROM..TO of ROOT and jump to one."
  (pr-review--helm-by-file
   (format "Changes in %s" label) root from to
   (pr-review--searchable-lines
    (pr-review--parse-added-lines (pr-review--diff "-U0" from to)))))

;;; ---------------------------------------------------------------------------
;;; Commands
;;; ---------------------------------------------------------------------------

;;;###autoload
(defun pr-review-search-changes ()
  "Narrow down lines added or modified by the target and jump to one."
  (interactive)
  (pr-review--with-target (root from to label)
    (pr-review--search-range root label from to)))

;;;###autoload
(defun pr-review-find-file ()
  "Show the target's changed files as a hub: open one, or toggle viewed marks.
The file of the current buffer is preselected, so you can come back here,
pick the next file, and keep track of which files are done (✓)."
  (interactive)
  (pr-review--with-target (root from to label)
    (pr-review--files-hub root from to label (car (pr-review--current-position root)))))

(defun pr-review--files-hub (root from to label current)
  "Helm file hub for FROM..TO of ROOT titled with LABEL; preselect CURRENT.
Lock files etc. (skipped by navigation) are shown with \"-\" and not counted."
  (let* ((default-directory root)       ; helm actions run in the origin buffer
         (files (or (pr-review--changed-files from to)
                    (user-error "pr-review: No changed files")))
         (numstat (pr-review--numstat from to))
         (review (cl-remove-if #'pr-review--skip-file-p (mapcar #'cdr files)))
         (viewed (cl-count-if (lambda (f) (pr-review--viewed-p root from to f)) review)))
    (helm :sources
          (helm-build-sync-source (format "Files (%d/%d viewed): %s" viewed (length review) label)
            :candidates (mapcar (pcase-lambda (`(,status . ,path))
                                  (cons (format "%s %s  %-9s  %s"
                                                (if (pr-review--skip-file-p path)
                                                    (propertize "-" 'face 'shadow)
                                                  (pr-review--viewed-mark root from to path))
                                                status (pr-review--file-stat numstat path) path)
                                        path))
                                files)
            :candidate-number-limit 10000
            :action `(("Open at first change" .
                       ,(lambda (f)
                          (let ((default-directory root))
                            (pr-review--goto root (cons f (pr-review--first-change-line from to f))
                                             to))))
                      ("Toggle viewed ✓ (several marked: mark all viewed) and reopen" .
                       ,(lambda (_)
                          (let ((marked (helm-marked-candidates)))
                            (dolist (f marked)
                              (pr-review--set-viewed root from to f
                                                     (or (cdr marked)
                                                         (not (pr-review--viewed-p root from to f)))))
                            (pr-review--files-hub root from to label (car (last marked))))))))
          ;; 表示行は "✓ M  +7 -1     PATH"。helm バッファ内の行末にマッチさせる
          :preselect (and current (concat "  " (regexp-quote current) "$"))
          :buffer "*helm pr-review files*")))

;;;###autoload
(defun pr-review-grep (pattern)
  "Run git grep for PATTERN (extended regexp) in the files changed by the target.
Files are searched as of the target's last commit.  Unlike
`pr-review-search-changes', unchanged lines around the changes are included."
  (interactive
   (progn
     ;; 検索語より先に対象を決める(未選択時に入力が無駄にならないように)
     (unless (gethash (pr-review--root) pr-review--target-cache) (pr-review-select))
     (list (read-string (format-prompt "PR grep" (thing-at-point 'symbol t))
                        nil nil (thing-at-point 'symbol t)))))
  (pr-review--with-target (root from to label)
    (let ((files (cl-remove-if #'pr-review--skip-file-p
                               (mapcar #'cdr (pr-review--changed-files from to))))
          (prefix (concat to ":")))
      (unless files (user-error "pr-review: No changed files"))
      (pcase-let ((`(,code . ,out)
                   (apply #'pr-review--git "grep" "-z" "-n" "-I" "-E" "--no-color"
                          "-e" pattern to "--" files)))
        (when (> code 1) (user-error "pr-review: git grep failed: %s" (string-trim out)))
        (pr-review--helm-by-file
         (format "Grep %s in %s" pattern label) root from to
         (cl-loop for l in (split-string out "\n" t)
                  ;; -z: "TO:FILE\0LINE\0TEXT" (ファイル名に ':' があっても安全)
                  for (file lnum text) = (split-string (string-remove-prefix prefix l) "\0")
                  when (and lnum text)
                  collect (list file (string-to-number lnum) text)))))))

;;;###autoload
(defun pr-review-show-diff ()
  "Show the target's whole diff in magit."
  (interactive)
  (require 'magit)
  (pr-review--with-target (root from to label)
    (magit-diff-range (format "%s..%s" from to))))

(defun pr-review--range-commits (from to)
  "Return ((DISPLAY . HASH) ...) for commits in FROM..TO, newest first."
  ;; マージコミットは PR 全体と同じ差分になるだけなので除外
  (cl-loop for l in (pr-review--git-lines "log" "--no-color" "--no-merges"
                                          "--format=%H%x09%h%x09%s%x09%an%x09%ar"
                                          (if (equal from pr-review--empty-tree)
                                              to
                                            (format "%s..%s" from to)))
           for (full hash subject author date) = (split-string l "\t")
           collect (cons (format "%s  %s  %s"
                                 (propertize hash 'face 'font-lock-constant-face)
                                 subject
                                 (propertize (format "(%s, %s)" author date) 'face 'shadow))
                         full)))

;;;###autoload
(defun pr-review-commits ()
  "Pick a commit of the target and narrow the review target to it.
Every command (file hub, next file, search ...) then works on that commit;
`pr-review-up' returns to the original target."
  (interactive)
  (pr-review--with-target (root from to label)
    (let ((commits (or (pr-review--range-commits from to)
                       (user-error "pr-review: No commits in %s" label)))
          (parent (gethash root pr-review--target-cache)))
      (helm :sources (helm-build-sync-source (format "Commits: %s" label)
                       :candidates commits
                       :candidate-number-limit 10000
                       :action `(("Narrow target to this commit" .
                                  ,(lambda (h) (pr-review--narrow-to-commit root parent h)))
                                 ("Show commit diff (magit)" .
                                  ,(lambda (h) (require 'magit) (magit-show-commit h)))))
            :buffer "*helm pr-review commits*"))))

(defun pr-review--set-target (root target)
  "Make TARGET the review target of ROOT and refresh highlighting."
  (puthash root target pr-review--target-cache)
  (pr-review-overlay-refresh-all)
  (message "pr-review: target = %s" (plist-get target :label)))

(defun pr-review--narrow-to-commit (root current hash)
  "Narrow ROOT's review target to commit HASH.
The parent is CURRENT, or CURRENT's parent if it is already narrowed, so
`pr-review-up' always returns to the original PR / commit."
  (let* ((default-directory root)
         (parent (or (plist-get current :parent) current))
         (commit (pr-review--commit-target hash)))
    (pr-review--set-target
     root (list :label (format "%s › %s" (plist-get parent :label) (plist-get commit :label))
                :from (plist-get commit :from)
                :to (plist-get commit :to)
                :parent parent))))

;;;###autoload
(defun pr-review-up ()
  "Return from a commit narrowed by `pr-review-commits' to the original target."
  (interactive)
  (let* ((root (pr-review--root))
         (parent (plist-get (gethash root pr-review--target-cache) :parent)))
    (unless parent (user-error "pr-review: Not narrowed to a commit"))
    (pr-review--set-target root parent)))

;;;###autoload
(defun pr-review-clear ()
  "Forget the current repository's review target and remove its highlighting."
  (interactive)
  (remhash (pr-review--root) pr-review--target-cache)
  (pr-review-overlay-refresh-all)
  (message "pr-review: target cleared"))

(defconst pr-review--help-text
  "PR レビュー: 選んだ PR / コミットの変更箇所だけを、lsp でコードを辿りながら読む

  現在の対象: %s

キー
  \\[pr-review-select]	レビュー対象の PR / コミットを一覧から選ぶ
  \\[pr-review-next-change]	次の変更箇所へ（ファイルをまたいで巡回）
  \\[pr-review-previous-change]	前の変更箇所へ
  \\[pr-review-toggle-original]	カーソル位置の変更箇所の「変更前」を表示/非表示
  \\[pr-review-next-file]	このファイルは確認済み(✓)にして、未確認の次のファイルへ
	  ↑ n / p / o / j は実行直後なら単独キーで続けて押せる
  \\[pr-review-find-file]	ファイル一覧（拠点）: ✓ 確認済み / +追加 -削除 / 今のファイルを選択済み
	  RET: 最初の変更箇所へ  TAB→アクション: ✓ の切り替え（C-SPC で複数可）
  \\[pr-review-search-changes]	変更された行だけを絞り込み検索（ファイルごと、C-o で次のファイル）
  \\[pr-review-grep]	変更ファイル全体を git grep（ファイルごと、対象の時点の内容）
  \\[pr-review-show-diff]	差分全体を magit で表示
  \\[pr-review-commits]	対象内のコミットを1つ選んで、対象をそのコミットに絞り込む
  \\[pr-review-up]	コミットの絞り込みから元の PR に戻る
  \\[pr-review-clear]	対象を解除してハイライトを消す
  \\[pr-review-help]	このヘルプ

コードを読む（lsp が有効なバッファ: TypeScript など。init.el の lsp 設定）
  M-.	定義へジャンプ（飛んだ先でも PR の変更行はハイライトされる）
  M-,	ジャンプ元へ戻る
  C-c d	カーソル下のシンボルのドキュメントをその場に表示
  C-c D	定義を開かずに覗く（peek）
  C-c r	参照箇所を一覧（peek）
  C-c i	実装を辿る（インターフェース → 実装 / オーバーライド先）
  C-c s	プロジェクト全体からシンボルを検索（helm）
	  ※ lsp がエラーを出す箇所 = 存在しない API・型の不一致の疑い（AI コードで要確認）

流れ
  1. 対象を選ぶ → どの経路で開いたファイルでも変更行がハイライトされる
       緑背景 = 追加/変更行、fringe の赤三角 = 削除のみの位置
  2. ファイル一覧で規模を把握
  3. ファイルを開き、n で変更箇所を順に読む
     怪しい箇所は o で「変更前」を表示して比較
     知らない関数・型は C-c d で説明を見る / C-c D で覗く / M-. で飛んで M-, で戻る
     影響範囲は C-c r（参照）・C-c i（実装）で確認
  4. 「このファイルはOK」なら j → 未確認の次のファイルへ。迷ったらファイル一覧に戻る
     コミット単位で見たいときは コミットに絞り込み → 同じように j / ファイル一覧 → 戻る
  5. 行検索 / grep で横断して探す。終わったら対象を解除

メモ
  - HEAD や作業ツリーとは無関係。対象はリポジトリごとに記憶される
  - 作業ツリーが対象の時点と違うファイルは、その時点の版を読み取り専用で開く
    （その版では lsp が動かない。lsp で辿りたいときは PR ブランチを checkout する）
  - lock ファイルは巡回/行検索から除外（`pr-review-skip-files-regexp'）"
  "Body of `pr-review-help'; %s is replaced with the current target.")

;;;###autoload
(defun pr-review-help ()
  "Show pr-review keys, the review flow and the current target."
  (interactive)
  (let* ((root (ignore-errors (pr-review--root)))
         (target (and root (gethash root pr-review--target-cache)))
         (current (if target
                      (format "%s (%s..%s)" (plist-get target :label)
                              (substring (plist-get target :from) 0 7)
                              (substring (plist-get target :to) 0 7))
                    "なし（まず対象を選ぶ）")))
    (with-help-window "*pr-review help*"
      (with-current-buffer standard-output
        (insert (format (substitute-command-keys pr-review--help-text) current))))))

(provide 'pr-review)
;;; pr-review.el ends here
