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
;;   pr-review-find-file       変更されたファイルだけを選んで開く
;;   pr-review-grep            変更されたファイル全体を git grep (TO 時点)
;;   pr-review-show-diff       対象の差分を magit で表示
;;   pr-review-commits         対象内のコミットを選び、そのコミットの変更行/ファイル/差分を確認

;;; Code:

(require 'cl-lib)
(require 'subr-x)
(require 'helm)

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
  (goto-char (point-min))
  (forward-line (1- (cdr loc)))
  (recenter))

(defun pr-review--format (file line text)
  "Format a helm candidate display string for FILE, LINE and TEXT."
  (format "%s:%s: %s"
          (propertize file 'face 'helm-grep-file)
          (propertize (number-to-string line) 'face 'helm-grep-lineno)
          text))

(defun pr-review--helm-locations (title root candidates rev)
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

(defun pr-review--helm-files (title root files rev)
  "Pick one of FILES ((STATUS . PATH) ...) under TITLE; open it as of REV."
  (unless files (user-error "pr-review: No changed files"))
  (helm :sources (helm-build-sync-source title
                   :candidates (mapcar (lambda (sf)
                                         (cons (format "%s  %s" (car sf) (cdr sf)) (cdr sf)))
                                       files)
                   :candidate-number-limit 10000
                   :action (lambda (f) (pr-review--goto root (cons f 1) rev)))
        :buffer "*helm pr-review files*"))

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

(defun pr-review--line-candidates (lines)
  "Turn LINES ((FILE LINE TEXT) ...) into helm location candidates."
  (cl-loop for (file line text) in lines
           unless (string-blank-p text)
           collect (cons (pr-review--format file line text) (cons file line))))

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
  (pr-review--helm-locations
   (format "Changes: %s" label)
   root
   (pr-review--line-candidates
    (pr-review--parse-added-lines (pr-review--diff "-U0" from to)))
   to))

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
  "Open one of the files changed by the target."
  (interactive)
  (pr-review--with-target (root from to label)
    (pr-review--helm-files (format "Files: %s" label) root
                           (pr-review--changed-files from to) to)))

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
    (let ((files (mapcar #'cdr (pr-review--changed-files from to)))
          (prefix (concat to ":")))
      (unless files (user-error "pr-review: No changed files"))
      (pcase-let ((`(,code . ,out)
                   (apply #'pr-review--git "grep" "-z" "-n" "-I" "-E" "--no-color"
                          "-e" pattern to "--" files)))
        (when (> code 1) (user-error "pr-review: git grep failed: %s" (string-trim out)))
        (pr-review--helm-locations
         (format "Grep %s: %s" pattern label)
         root
         (cl-loop for l in (split-string out "\n" t)
                  ;; -z: "TO:FILE\0LINE\0TEXT" (ファイル名に ':' があっても安全)
                  for (file lnum text) = (split-string (string-remove-prefix prefix l) "\0")
                  when (and lnum text)
                  collect (let ((line (string-to-number lnum)))
                            (cons (pr-review--format file line text)
                                  (cons file line))))
         to)))))

;;;###autoload
(defun pr-review-show-diff ()
  "Show the target's whole diff in magit."
  (interactive)
  (require 'magit)
  (pr-review--with-target (root from to label)
    (magit-diff-range (format "%s..%s" from to))))

(defun pr-review--range-commits (from to)
  "Return ((DISPLAY . HASH) ...) for commits in FROM..TO, newest first."
  (cl-loop for l in (pr-review--git-lines "log" "--no-color"
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
  "Pick a commit of the target and review only that commit."
  (interactive)
  (pr-review--with-target (root from to label)
    (let ((commits (pr-review--range-commits from to)))
      (unless commits (user-error "pr-review: No commits in %s" label))
      (helm :sources (helm-build-sync-source (format "Commits: %s" label)
                       :candidates commits
                       :candidate-number-limit 10000
                       :action `(("Search changed lines" .
                                  ,(lambda (h)
                                     (let ((c (pr-review--commit-target h)))
                                       (pr-review--search-range root (plist-get c :label)
                                                                (plist-get c :from) h))))
                                 ("Open changed file" .
                                  ,(lambda (h)
                                     (let ((c (pr-review--commit-target h)))
                                       (pr-review--helm-files
                                        (format "Files: %s" (plist-get c :label)) root
                                        (pr-review--changed-files (plist-get c :from) h) h))))
                                 ("Show commit diff (magit)" .
                                  ,(lambda (h) (require 'magit) (magit-show-commit h)))))
            :buffer "*helm pr-review commits*"))))

(provide 'pr-review)
;;; pr-review.el ends here
