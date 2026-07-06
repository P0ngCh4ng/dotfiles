;;; claude-code-projects.el --- Project shortcuts for Claude Code -*- lexical-binding: t; -*-

;;; Commentary:
;; Extends the official claude-code package with:
;; - Predefined project shortcuts
;; - Cage integration for advanced configuration
;; - Multiple session management per project
;; - Git worktree integration (one worktree per session, isolated checkouts)
;; - Session switching and renaming
;; - Crash recovery (startup-time cleanup of stale cage entries)
;; - Fix for non-projectile directories (empty directories without .git)
;;
;; Session data model:
;;   `claude-code-projects-sessions' is a list of plists, one per session:
;;     (:project STR :buffer-name STR :directory STR
;;      :worktree-p BOOL :branch STR-OR-NIL :created-at TIME)

;;; Code:

(require 'cl-lib)

;; claude-codeパッケージをロード（遅延ロード対応）
(require 'claude-code nil t)

;; Forward declarations
(declare-function claude-code-vterm-mode "claude-code-ui" ())
(declare-function vterm-send-key "vterm" (key &optional shift meta ctrl))
(defvar vterm-shell)

;;; ---------------------------------------------------------------------------
;;; Tree / split-screen support (Ctrl+T = F5 in Claude Code 2.x)
;;;
;;; Claude Code 2.x keybindings (from binary inspection):
;;;   ^T / F5  - toggle split screen (file tree)
;;;   ^Y / F2  - view or edit file
;;;   ^X / F3  - set bookmark
;;;   ^R / F4  - restore bookmark
;;;   ^Z / F1  - help
;;; ---------------------------------------------------------------------------

;;;###autoload
(defun claude-code-toggle-tree ()
  "Toggle Claude Code split screen / file tree view.
Sends F5 (equivalent to Ctrl+T) to the Claude Code vterm buffer.
This corresponds to the \\='toggle split screen\\=' command in Claude Code 2.x."
  (interactive)
  (claude-code-with-vterm-buffer
   (lambda () (vterm-send-key "<f5>"))))

;;;###autoload
(defun claude-code-send-f2 ()
  "Send F2 (view/edit file) to Claude Code buffer."
  (interactive)
  (claude-code-with-vterm-buffer
   (lambda () (vterm-send-key "<f2>"))))

;;;###autoload
(defun claude-code-send-f1 ()
  "Send F1 (help) to Claude Code buffer."
  (interactive)
  (claude-code-with-vterm-buffer
   (lambda () (vterm-send-key "<f1>"))))

;; Register F-key bindings in claude-code-vterm-mode-map after the package loads.
(with-eval-after-load 'claude-code-ui
  (define-key claude-code-vterm-mode-map (kbd "<f5>") #'claude-code-toggle-tree)
  (define-key claude-code-vterm-mode-map (kbd "<f2>") #'claude-code-send-f2)
  (define-key claude-code-vterm-mode-map (kbd "<f1>") #'claude-code-send-f1)
  ;; C-c t as an additional mnemonic for tree toggle
  (define-key claude-code-vterm-mode-map (kbd "C-c t") #'claude-code-toggle-tree))

(defgroup claude-code-projects nil
  "Project shortcuts for Claude Code."
  :group 'claude-code
  :prefix "claude-code-projects-")

(defcustom claude-code-projects-list
  '(("dotfiles" . "~/dotfiles")
    ("pon" . "~/pon")
    ("sokko" . "~/sokko")
    ("chatclinic" . "~/chatclinic")
    ("AutomationVideo" . "~/AutomationVideo")
    ("mcpCreate" . "~/mcpCreate"))
  "List of frequently used projects for Claude Code.
Each entry is a cons cell (PROJECT-NAME . DIRECTORY)."
  :type '(alist :key-type string :value-type directory)
  :group 'claude-code-projects)

(defcustom claude-code-projects-use-cage t
  "Whether to use cage for launching Claude Code."
  :type 'boolean
  :group 'claude-code-projects)

(defcustom claude-code-projects-cage-config
  "~/.config/cage/presets.yaml"
  "Path to cage configuration file."
  :type 'file
  :group 'claude-code-projects)

(defvar claude-code-projects-sessions nil
  "List of active Claude Code sessions.
Each entry is a plist with keys:
  :project       Project name (string, key in `claude-code-projects-list')
  :buffer-name   Vterm buffer name (string)
  :directory     Absolute directory where the session runs (string)
  :worktree-p    Non-nil if `:directory' is a git worktree, not the main repo
  :branch        Branch name (string) when `:worktree-p' is non-nil, else nil
  :created-at    Timestamp from `current-time'")

(defun claude-code-projects--get-command ()
  "Get the Claude Code launch command."
  (if claude-code-projects-use-cage
      (format "cage -config %s -preset claude-code -- bash -c 'env CLAUDE_CODE_DISABLE_ITERM2=1 claude --dangerously-skip-permissions'"
              (shell-quote-argument (expand-file-name claude-code-projects-cage-config)))
    "env CLAUDE_CODE_DISABLE_ITERM2=1 claude --dangerously-skip-permissions"))

;;; ---------------------------------------------------------------------------
;;; Session helpers (plist-based)
;;; ---------------------------------------------------------------------------

(defun claude-code-projects--make-session (project buffer-name directory
                                                  &optional worktree-p branch)
  "Create a session plist.
PROJECT is the project key, BUFFER-NAME the vterm buffer, DIRECTORY the
absolute working directory.  When WORKTREE-P is non-nil, BRANCH is the
checked-out branch in that worktree."
  (list :project project
        :buffer-name buffer-name
        :directory (expand-file-name directory)
        :worktree-p (and worktree-p t)
        :branch (and worktree-p branch)
        :created-at (current-time)))

(defun claude-code-projects--session-live-p (session)
  "Return non-nil when SESSION's buffer is still alive."
  (and (listp session)
       (plist-get session :buffer-name)
       (let ((buf (get-buffer (plist-get session :buffer-name))))
         (and buf (buffer-live-p buf)))))

(defun claude-code-projects--session-by-buffer (buffer-or-name)
  "Return the session plist whose `:buffer-name' matches BUFFER-OR-NAME."
  (let ((name (cond
               ((bufferp buffer-or-name) (buffer-name buffer-or-name))
               ((stringp buffer-or-name) buffer-or-name)
               (t nil))))
    (when name
      (cl-find-if (lambda (s)
                    (and (listp s)
                         (equal (plist-get s :buffer-name) name)))
                  claude-code-projects-sessions))))

(defun claude-code-projects--gc-sessions ()
  "Remove dead sessions and stale (non-plist) entries.
Returns the cleaned session list and assigns it to
`claude-code-projects-sessions'."
  (setq claude-code-projects-sessions
        (cl-remove-if-not #'claude-code-projects--session-live-p
                          claude-code-projects-sessions))
  claude-code-projects-sessions)

(defun claude-code-projects--register-session (session)
  "Add SESSION plist to the active session list, replacing any duplicate buffer."
  (let ((name (plist-get session :buffer-name)))
    (setq claude-code-projects-sessions
          (cl-remove-if (lambda (s)
                          (and (listp s)
                               (equal (plist-get s :buffer-name) name)))
                        claude-code-projects-sessions))
    (push session claude-code-projects-sessions)
    session))

(defun claude-code-projects--session-display-name (session)
  "Return a human-readable label for SESSION."
  (let ((proj (plist-get session :project))
        (branch (plist-get session :branch))
        (wt (plist-get session :worktree-p)))
    (if wt
        (format "%s [%s]" proj (or branch "?"))
      proj)))

;;; ---------------------------------------------------------------------------
;;; Cage YAML manipulation (private)
;;; ---------------------------------------------------------------------------
;;
;; cage's `~/.config/cage/presets.yaml' has no glob support, so each worktree
;; path is added explicitly.  We delimit our entries with a fenced marker block
;; so unrelated entries (manual or generated by `bin/update-cage-config') are
;; preserved.  The block lives under
;; `presets > claude-code > allow:' and uses 6-space indent.

(defconst claude-code-projects--cage-indent "      "
  "Indent string (6 spaces) used for entries under `allow:'.")

(defconst claude-code-projects--cage-marker-start
  "      # === AUTO-GENERATED WORKTREES START ==="
  "Opening marker for the worktree block in the cage YAML.")

(defconst claude-code-projects--cage-marker-end
  "      # === AUTO-GENERATED WORKTREES END ==="
  "Closing marker for the worktree block in the cage YAML.")

(defun claude-code-projects--cage-config-path ()
  "Return the absolute cage config path."
  (expand-file-name claude-code-projects-cage-config))

(defun claude-code-projects--cage-quote-entry (path)
  "Return the YAML line string for adding PATH under `allow:'."
  (format "%s- \"%s\"" claude-code-projects--cage-indent path))

(defun claude-code-projects--cage-with-buffer (fn)
  "Open the cage config in a temp buffer, call FN with point at start.
FN may mutate the buffer; the result is written back via a temp-file
rename so a crash cannot leave the cage YAML truncated.
Returns whatever FN returns."
  (let* ((file (claude-code-projects--cage-config-path))
         (tmp  (concat file ".emacs-tmp")))
    (unless (file-exists-p file)
      (user-error "Cage config not found: %s" file))
    (let (result)
      (with-temp-buffer
        (insert-file-contents file)
        (goto-char (point-min))
        (setq result (funcall fn))
        (write-region nil nil tmp nil 'silent)
        (rename-file tmp file t))
      result)))

(defun claude-code-projects--cage-find-marker-region ()
  "When point is in a temp buffer holding the cage YAML, locate the marker block.
Returns a cons (BEGIN-OF-START-LINE . END-OF-END-LINE) or nil if absent.
Does not move point on failure; on success leaves point at the END marker."
  (save-excursion
    (goto-char (point-min))
    (when (re-search-forward
           (concat "^" (regexp-quote claude-code-projects--cage-marker-start) "$")
           nil t)
      (let ((start (line-beginning-position)))
        (when (re-search-forward
               (concat "^" (regexp-quote claude-code-projects--cage-marker-end) "$")
               nil t)
          (cons start (line-end-position)))))))

(defun claude-code-projects--cage-ensure-markers ()
  "Ensure the worktree marker block exists in the current cage-YAML buffer.
If absent, insert an empty block immediately before the `allow-keychain:'
line of the `claude-code:' preset (the natural end of `allow:').  Signals
`user-error' when no suitable insertion point is found."
  (or (claude-code-projects--cage-find-marker-region)
      (save-excursion
        (goto-char (point-min))
        ;; Find `allow-keychain:' (or any line outdented to 4 spaces ending
        ;; the `allow:' block under claude-code).  The simplest robust anchor
        ;; is `allow-keychain:' which the existing template emits.
        (unless (re-search-forward "^    allow-keychain:" nil t)
          (user-error
           "Cannot locate `allow-keychain:' anchor in cage config; aborting"))
        (beginning-of-line)
        (insert claude-code-projects--cage-marker-start "\n"
                claude-code-projects--cage-marker-end "\n")
        ;; Re-locate the freshly inserted region.
        (claude-code-projects--cage-find-marker-region))))

(defun claude-code-projects--cage-list-worktree-paths ()
  "Return the list of worktree paths currently registered in the cage YAML."
  (let ((file (claude-code-projects--cage-config-path)))
    (if (not (file-exists-p file))
        nil
      (with-temp-buffer
        (insert-file-contents file)
        (let ((region (claude-code-projects--cage-find-marker-region))
              paths)
          (when region
            (save-excursion
              (goto-char (car region))
              (forward-line 1)
              (while (and (< (point) (cdr region))
                          (re-search-forward
                           "^      - \"\\([^\"]+\\)\"$"
                           (cdr region) t))
                (push (match-string 1) paths))))
          (nreverse paths))))))

(defun claude-code-projects--cage-add-worktree-path (path)
  "Add absolute PATH to the cage YAML worktree block (idempotent).
Returns t when the file was modified, nil when PATH was already present."
  (let ((abs (expand-file-name path)))
    (claude-code-projects--cage-with-buffer
     (lambda ()
       (let ((region (claude-code-projects--cage-ensure-markers))
             (entry (claude-code-projects--cage-quote-entry abs)))
         ;; Check for an existing entry between the markers (exact match).
         (if (save-excursion
               (goto-char (car region))
               (forward-line 1)
               (let ((end (cdr region))
                     found)
                 (while (and (not found) (< (point) end))
                   (when (looking-at-p (concat "^" (regexp-quote entry) "$"))
                     (setq found t))
                   (forward-line 1))
                 found))
             nil
           ;; Insert immediately before the END marker line.
           (goto-char (cdr region))
           (beginning-of-line)
           (insert entry "\n")
           t))))))

(defun claude-code-projects--cage-remove-worktree-path (path)
  "Remove absolute PATH from the cage YAML worktree block.
Returns t when an entry was removed, nil when PATH was not present."
  (let ((abs (expand-file-name path)))
    (claude-code-projects--cage-with-buffer
     (lambda ()
       (let ((region (claude-code-projects--cage-find-marker-region))
             (entry (claude-code-projects--cage-quote-entry abs))
             (removed nil))
         (when region
           (save-excursion
             (goto-char (car region))
             (forward-line 1)
             (while (and (not removed) (< (point) (cdr region)))
               (if (looking-at-p (concat "^" (regexp-quote entry) "$"))
                   (progn
                     (delete-region (line-beginning-position)
                                    (line-beginning-position 2))
                     (setq removed t))
                 (forward-line 1)))))
         removed)))))

;;; ---------------------------------------------------------------------------
;;; Git worktree primitives (private)
;;; ---------------------------------------------------------------------------

(defcustom claude-code-projects-protected-branches '("main" "master")
  "Branches that may not be checked out into a new worktree.
Per design decision, the project's primary branch should not be duplicated
into a parallel worktree because the main repo already holds it."
  :type '(repeat string)
  :group 'claude-code-projects)

(defun claude-code-projects--git-available-p ()
  "Return non-nil when the `git' executable is on PATH."
  (and (executable-find "git") t))

(defun claude-code-projects--git-call (dir &rest args)
  "Run git with ARGS in DIR and return (EXIT-CODE . OUTPUT-STRING).
OUTPUT-STRING contains both stdout and stderr."
  (with-temp-buffer
    (let* ((default-directory (file-name-as-directory (expand-file-name dir)))
           (exit (apply #'process-file "git" nil t nil args)))
      (cons exit (buffer-substring-no-properties (point-min) (point-max))))))

(defun claude-code-projects--git-repo-p (dir)
  "Return non-nil when DIR is inside a git working tree."
  (and (file-directory-p dir)
       (claude-code-projects--git-available-p)
       (zerop (car (claude-code-projects--git-call
                    dir "rev-parse" "--is-inside-work-tree")))))

(defun claude-code-projects--git-current-branch (dir)
  "Return the current branch name in DIR, or nil if detached/unknown."
  (let* ((res (claude-code-projects--git-call
               dir "rev-parse" "--abbrev-ref" "HEAD"))
         (out (string-trim (cdr res))))
    (cond
     ((not (zerop (car res))) nil)
     ((string= out "HEAD") nil)
     (t out))))

(defun claude-code-projects--git-list-branches (dir)
  "Return a list of local branch names in DIR."
  (let ((res (claude-code-projects--git-call
              dir "branch" "--format=%(refname:short)")))
    (when (zerop (car res))
      (split-string (cdr res) "\n" t "[[:space:]]+"))))

(defun claude-code-projects--git-list-worktrees (dir)
  "Return list of worktrees for the repo containing DIR.
Each element is a plist (:path :branch :head :main-p).
`:branch' is nil for detached HEAD; `:main-p' is non-nil for the
primary worktree (the first entry returned by git)."
  (let ((res (claude-code-projects--git-call dir "worktree" "list" "--porcelain")))
    (unless (zerop (car res))
      (user-error "git worktree list failed in %s: %s" dir (cdr res)))
    (let ((blocks (split-string (cdr res) "\n\n" t))
          (results nil)
          (first t))
      (dolist (block blocks)
        (let ((path nil) (branch nil) (head nil))
          (dolist (line (split-string block "\n" t))
            (cond
             ((string-match "\\`worktree \\(.*\\)\\'" line)
              (setq path (match-string 1 line)))
             ((string-match "\\`HEAD \\(.*\\)\\'" line)
              (setq head (match-string 1 line)))
             ((string-match "\\`branch refs/heads/\\(.*\\)\\'" line)
              (setq branch (match-string 1 line)))
             ((string-match "\\`detached\\'" line)
              (setq branch nil))))
          (when path
            (push (list :path (expand-file-name path)
                        :branch branch
                        :head head
                        :main-p first)
                  results))
          (setq first nil)))
      (nreverse results))))

(defun claude-code-projects--git-worktree-dirty-p (path)
  "Return non-nil when PATH (a git worktree) has uncommitted changes."
  (let ((res (claude-code-projects--git-call path "status" "--porcelain")))
    (and (zerop (car res))
         (not (string-empty-p (string-trim (cdr res)))))))

(defun claude-code-projects--git-add-worktree (repo-dir target-path branch
                                                        &optional new-branch-p)
  "Create a worktree at TARGET-PATH for BRANCH in REPO-DIR.
When NEW-BRANCH-P is non-nil, create BRANCH from current HEAD.
Signals `user-error' on failure with git's stderr."
  (let* ((args (if new-branch-p
                   (list "worktree" "add" "-b" branch target-path)
                 (list "worktree" "add" target-path branch)))
         (res (apply #'claude-code-projects--git-call repo-dir args)))
    (unless (zerop (car res))
      (user-error "git worktree add failed: %s" (string-trim (cdr res))))
    target-path))

(defun claude-code-projects--git-remove-worktree (repo-dir target-path
                                                           &optional force)
  "Remove worktree at TARGET-PATH from REPO-DIR.
When FORCE is non-nil, pass --force.  Signals `user-error' on failure."
  (let* ((args (append (list "worktree" "remove")
                       (and force '("--force"))
                       (list target-path)))
         (res (apply #'claude-code-projects--git-call repo-dir args)))
    (unless (zerop (car res))
      (user-error "git worktree remove failed: %s" (string-trim (cdr res))))
    t))

(defun claude-code-projects--sanitize-branch-name (branch)
  "Make BRANCH safe to use as a directory name component.
Replaces `/', `:', whitespace, and other path-unfriendly characters with `-'."
  (let ((s branch))
    (setq s (replace-regexp-in-string "[/\\\\:[:space:]]+" "-" s))
    (setq s (replace-regexp-in-string "[^A-Za-z0-9._-]" "-" s))
    (setq s (replace-regexp-in-string "-+" "-" s))
    (setq s (replace-regexp-in-string "\\`-+\\|-+\\'" "" s))
    s))

(defun claude-code-projects--derive-worktree-path (project-dir branch)
  "Compute the conventional worktree path for BRANCH inside PROJECT-DIR.
Layout: <parent>/<project-name>-worktrees/<sanitized-branch>/
Examples:
  ~/dotfiles + feature-a -> ~/dotfiles-worktrees/feature-a/
  ~/work/SOKKO + bugfix  -> ~/work/SOKKO-worktrees/bugfix/"
  (let* ((abs (directory-file-name (expand-file-name project-dir)))
         (parent (file-name-directory abs))
         (project-name (file-name-nondirectory abs))
         (safe (claude-code-projects--sanitize-branch-name branch))
         (container (expand-file-name
                     (concat project-name "-worktrees") parent)))
    (when (string-empty-p safe)
      (user-error "Branch name `%s' becomes empty after sanitization" branch))
    (file-name-as-directory (expand-file-name safe container))))

;;; ---------------------------------------------------------------------------
;;; Session creation core (extracted helper, Phase 1 minimal version)
;;; ---------------------------------------------------------------------------

(defun claude-code-projects--start-session-in-dir (project directory
                                                           &optional worktree-p branch
                                                           force-buffer-name)
  "Start a Claude Code vterm session for PROJECT in DIRECTORY.
WORKTREE-P / BRANCH describe the session's git context.  When
FORCE-BUFFER-NAME is non-nil it is used as-is; otherwise a name is derived
from DIRECTORY and made unique with `generate-new-buffer-name'.
Returns the registered session plist."
  (let* ((expanded-dir (expand-file-name directory))
         (normalized-root (directory-file-name expanded-dir)))
    (unless (file-directory-p expanded-dir)
      (user-error "Directory does not exist: %s" expanded-dir))
    (let* ((base-name (format "*claude:%s*" normalized-root))
           (buffer-name (or force-buffer-name
                            (if (get-buffer base-name)
                                (generate-new-buffer-name base-name)
                              base-name)))
           (command (claude-code-projects--get-command)))
      ;; Use let-bindings for dynamic variables so Emacs restores them correctly
      ;; on non-local exit — no unwind-protect or manual save/restore needed.
      (let ((default-directory expanded-dir)
            (vterm-shell command))
        (let ((buf (get-buffer-create buffer-name)))
          (with-current-buffer buf
            (setq default-directory expanded-dir)
            (require 'claude-code-ui)
            (claude-code-vterm-mode)
            ;; Prevent vterm from auto-renaming this buffer when the terminal
            ;; sets its title (triggered when vterm-buffer-name-string is set,
            ;; e.g. "vterm %s").  Must be set AFTER claude-code-vterm-mode
            ;; because define-derived-mode calls kill-all-local-variables first,
            ;; which would wipe any buffer-local binding set before mode init.
            (setq-local vterm-buffer-name-string nil))
          (switch-to-buffer-other-window buffer-name)
          (when claude-code-projects-use-cage
            (run-with-timer 1.5 nil
                            (lambda (dir buf-name)
                              (when-let ((b (get-buffer buf-name)))
                                (with-current-buffer b
                                  (require 'vterm)
                                  (vterm-send-string (format "cd \"%s\"" dir))
                                  (vterm-send-return))))
                            expanded-dir buffer-name))
          (let ((session (claude-code-projects--make-session
                          project buffer-name expanded-dir worktree-p branch)))
            (claude-code-projects--register-session session)
            (message "Started Claude Code session: %s"
                     (claude-code-projects--session-display-name session))
            session))))))

(defun claude-code-projects--prompt-existing-action (project)
  "Ask the user what to do when PROJECT already has a running session.
Returns one of the symbols `switch', `new', or signals `quit'."
  (let* ((prompt (format "Session exists for %s. (s)witch / (n)ew / (q)uit: "
                         project))
         (ch (read-char-choice prompt '(?s ?n ?q))))
    (pcase ch
      (?s 'switch)
      (?n 'new)
      (?q (user-error "Cancelled")))))

(defun claude-code-projects--current-dir ()
  "Return the best working directory for the current buffer.
Prefers `projectile-project-root' when inside a project;
falls back to `default-directory'."
  (or (and (fboundp 'projectile-project-root)
           (condition-case nil (projectile-project-root) (error nil)))
      default-directory))

(defun claude-code-projects--read-branch-name (project-dir)
  "Read a branch name (existing or new) for PROJECT-DIR.
Returns a cons (BRANCH . NEW-P) where NEW-P is non-nil when the branch
should be created.  Signals `user-error' when branch is empty or in
`claude-code-projects-protected-branches'."
  (let* ((existing (claude-code-projects--git-list-branches project-dir))
         (current (claude-code-projects--git-current-branch project-dir))
         (new-marker "[+] Create new branch...")
         (choices (cons new-marker existing))
         (picked (completing-read
                  (format "Branch (current: %s): " (or current "?"))
                  choices nil nil nil nil current))
         (branch (if (string= picked new-marker)
                     (read-string "New branch name: ")
                   picked))
         (new-p (and (string= picked new-marker) t)))
    (when (or (null branch) (string-empty-p (string-trim branch)))
      (user-error "Branch name is empty"))
    (setq branch (string-trim branch))
    (when (member branch claude-code-projects-protected-branches)
      (user-error
       "Branch `%s' is protected (in `claude-code-projects-protected-branches'); pick another"
       branch))
    (cons branch new-p)))

(defun claude-code-projects--resolve-target-path (project-dir branch)
  "Compute the worktree target path, prompting if it collides on disk.
Returns the final absolute path string."
  (let ((target (claude-code-projects--derive-worktree-path project-dir branch)))
    (while (file-exists-p (directory-file-name target))
      (setq target
            (file-name-as-directory
             (expand-file-name
              (read-directory-name
               (format "Path %s already exists. Pick alternate worktree path: "
                       target)
               (file-name-directory (directory-file-name target)))))))
    target))

(defun claude-code-projects--maybe-create-worktree (project project-dir)
  "Optionally create a git worktree for PROJECT rooted at PROJECT-DIR.
Returns a plist (:directory ABS-PATH :branch BRANCH) when a worktree was
created, or nil when the user declined or the project is not a git repo.
Performs cage registration when `claude-code-projects-use-cage' is non-nil."
  (cond
   ((not (claude-code-projects--git-available-p))
    (message "git not available; skipping worktree prompt")
    nil)
   ((not (claude-code-projects--git-repo-p project-dir))
    (message "%s is not a git repo; skipping worktree prompt" project)
    nil)
   ((not (y-or-n-p "Create git worktree for this session? "))
    nil)
   (t
    (pcase-let* ((`(,branch . ,new-p)
                  (claude-code-projects--read-branch-name project-dir))
                 (target
                  (claude-code-projects--resolve-target-path project-dir branch)))
      ;; git worktree add (clean up cage entry on failure to avoid drift).
      (claude-code-projects--git-add-worktree project-dir target branch new-p)
      (when claude-code-projects-use-cage
        (condition-case err
            (claude-code-projects--cage-add-worktree-path target)
          (error
           ;; Cage registration failed: roll back the worktree to keep state
           ;; consistent.  Report rollback failures instead of silencing them.
           (let ((rollback-err
                  (condition-case rb-err
                      (progn
                        (claude-code-projects--git-remove-worktree
                         project-dir target t)
                        nil)
                    (error rb-err))))
             (when rollback-err
               (message "WARNING: worktree rollback failed for %s: %s"
                        target (error-message-string rollback-err))))
           (signal (car err) (cdr err)))))
      (list :directory (directory-file-name target) :branch branch)))))

;;;###autoload
(defun claude-code-select-project (&optional force-new)
  "Select a project from predefined list and start Claude Code.
When a session already exists for the project, prompt to switch to it
or to create a new session.  With prefix arg FORCE-NEW (\\[universal-argument]),
skip the prompt and immediately create a new session, offering a git worktree."
  (interactive "P")
  (let* ((project (completing-read "Select project: " claude-code-projects-list nil t))
         (dir (cdr (assoc project claude-code-projects-list))))
    (cond
     ((not dir)
      (user-error "Project directory not configured for: %s" project))
     ((string-empty-p dir)
      (user-error "Project directory is empty for: %s" project))
     (t
      (let* ((expanded-dir (expand-file-name dir))
             (normalized-root (directory-file-name expanded-dir))
             (base-buffer-name (format "*claude:%s*" normalized-root))
             (existing-buffer (get-buffer base-buffer-name)))
        (unless (file-directory-p expanded-dir)
          (user-error "Directory does not exist: %s" expanded-dir))
        (cond
         ;; No existing session: create with canonical buffer name.
         ((not (and existing-buffer (buffer-live-p existing-buffer)))
          (claude-code-projects--start-session-in-dir
           project expanded-dir nil nil base-buffer-name))
         ;; force-new (C-u): skip prompt, go straight to new session.
         (force-new
          (let ((wt (claude-code-projects--maybe-create-worktree
                     project expanded-dir)))
            (if wt
                (claude-code-projects--start-session-in-dir
                 project (plist-get wt :directory)
                 t (plist-get wt :branch))
              (claude-code-projects--start-session-in-dir
               project expanded-dir nil nil
               (generate-new-buffer-name base-buffer-name)))))
         ;; Existing session: ask user.
         (t
          (pcase (claude-code-projects--prompt-existing-action project)
            ('switch
             (switch-to-buffer-other-window base-buffer-name)
             (message "Switched to existing session: %s" project))
            ('new
             (let ((wt (claude-code-projects--maybe-create-worktree
                        project expanded-dir)))
               (if wt
                   (claude-code-projects--start-session-in-dir
                    project (plist-get wt :directory)
                    t (plist-get wt :branch))
                 (claude-code-projects--start-session-in-dir
                  project expanded-dir nil nil
                  (generate-new-buffer-name base-buffer-name)))))))))))))

;;;###autoload
(defun claude-code-run-here (&optional force-new)
  "Start Claude Code in the current buffer's project or directory.
With prefix arg FORCE-NEW (\\[universal-argument]), always create a new
session without prompting.  Uses `projectile-project-root' when inside
a project; falls back to `default-directory'."
  (interactive "P")
  (let* ((dir (expand-file-name (claude-code-projects--current-dir)))
         (name (file-name-nondirectory (directory-file-name dir)))
         (canonical-buf-name (format "*claude:%s*"
                                    (directory-file-name dir))))
    (unless (file-directory-p dir)
      (user-error "Directory does not exist: %s" dir))
    (claude-code-projects--gc-sessions)
    ;; Check registry first; fall back to canonical buffer existence so that
    ;; sessions started by the official `claude-code-run' (Transient c) are
    ;; also recognised without being in our session registry.
    (let* ((registered (claude-code-projects--session-for-worktree dir))
           (canonical-live (and (not registered)
                                (let ((b (get-buffer canonical-buf-name)))
                                  (and b (buffer-live-p b) b))))
           (existing (or registered canonical-live)))
      (cond
       ;; No existing session anywhere: create with canonical buffer name.
       ((not existing)
        (claude-code-projects--start-session-in-dir name dir))
       ;; force-new (C-u): skip prompt, offer worktree like the 'new path.
       (force-new
        (let ((wt (claude-code-projects--maybe-create-worktree name dir)))
          (claude-code-projects--start-session-in-dir
           name
           (if wt (plist-get wt :directory) dir)
           (and wt t)
           (and wt (plist-get wt :branch)))))
       ;; Existing session: ask user.
       (t
        (pcase (claude-code-projects--prompt-existing-action name)
          ('switch
           (switch-to-buffer-other-window
            (if (listp existing)
                (plist-get existing :buffer-name)  ; from registry
              canonical-buf-name)))                ; from get-buffer
          ('new
           (let ((wt (claude-code-projects--maybe-create-worktree name dir)))
             (claude-code-projects--start-session-in-dir
              name
              (if wt (plist-get wt :directory) dir)
              (and wt t)
              (and wt (plist-get wt :branch)))))))))))

;;;###autoload
(defun claude-code-add-project ()
  "Add current directory to project list."
  (interactive)
  (let* ((dir (read-directory-name "Project directory: " default-directory))
         (name (read-string "Project name: " (file-name-nondirectory (directory-file-name dir)))))
    (customize-save-variable
     'claude-code-projects-list
     (cons (cons name dir) claude-code-projects-list))
    (message "Added project: %s -> %s" name dir)))

;;;###autoload
(defun claude-code-remove-project ()
  "Remove a project from the list."
  (interactive)
  (let ((project (completing-read "Remove project: " claude-code-projects-list nil t)))
    (customize-save-variable
     'claude-code-projects-list
     (assoc-delete-all project claude-code-projects-list))
    (message "Removed project: %s" project)))

;;;###autoload
(defun claude-code-edit-projects ()
  "Open customization buffer for project list."
  (interactive)
  (customize-variable 'claude-code-projects-list))

;;;###autoload
(defun claude-code-list-sessions ()
  "List all active Claude Code sessions."
  (interactive)
  (let ((sessions (claude-code-projects--gc-sessions)))
    (if sessions
        (message "Active sessions: %s"
                 (mapconcat (lambda (s)
                              (format "%s (%s)"
                                      (claude-code-projects--session-display-name s)
                                      (plist-get s :buffer-name)))
                            sessions ", "))
      (message "No active Claude Code sessions"))))

;;;###autoload
(defun claude-code-switch-session ()
  "Switch to a Claude Code session."
  (interactive)
  (let* ((sessions (claude-code-projects--gc-sessions))
         (choices (mapcar (lambda (s)
                            (cons (format "%s - %s"
                                          (claude-code-projects--session-display-name s)
                                          (plist-get s :buffer-name))
                                  (plist-get s :buffer-name)))
                          sessions)))
    (cond
     ((null choices)
      (message "No active Claude Code sessions"))
     (t
      (let* ((selected (completing-read "Switch to session: " choices nil t))
             (buffer-name (cdr (assoc selected choices)))
             (buffer (and buffer-name (get-buffer buffer-name))))
        (if buffer
            (switch-to-buffer-other-window buffer)
          (message "Session buffer no longer exists")))))))

;;;###autoload
(defun claude-code-kill-all-sessions ()
  "Kill all Claude Code sessions.
Worktree directories and cage entries are NOT touched here; use
`claude-code-cleanup-all-worktrees' for that."
  (interactive)
  (when (yes-or-no-p "Kill all Claude Code sessions? ")
    (dolist (s claude-code-projects-sessions)
      (when (listp s)
        (when-let ((buffer (get-buffer (plist-get s :buffer-name))))
          (kill-buffer buffer))))
    (setq claude-code-projects-sessions nil)
    (message "All Claude Code sessions killed")))

;;;###autoload
(defun claude-code-toggle-cage ()
  "Toggle cage usage on/off."
  (interactive)
  (setq claude-code-projects-use-cage (not claude-code-projects-use-cage))
  (message "Cage integration: %s"
           (if claude-code-projects-use-cage "ENABLED" "DISABLED")))

;;; ---------------------------------------------------------------------------
;;; Worktree commands (Phase 6)
;;; ---------------------------------------------------------------------------

(defun claude-code-projects--canonical-path (path)
  "Return canonical form of PATH for comparison.
Resolves symlinks (e.g. macOS /tmp -> /private/tmp) and strips any
trailing slash so that string `equal' works across producers
(git porcelain, user input, cage YAML)."
  (and path
       (directory-file-name (file-truename (expand-file-name path)))))

(defun claude-code-projects--session-for-worktree (path)
  "Return the live session plist whose `:directory' matches PATH, or nil."
  (let ((target (claude-code-projects--canonical-path path)))
    (cl-find-if
     (lambda (s)
       (and (claude-code-projects--session-live-p s)
            (equal (claude-code-projects--canonical-path
                    (plist-get s :directory))
                   target)))
     claude-code-projects-sessions)))

(defun claude-code-projects--collect-all-worktrees ()
  "Walk `claude-code-projects-list' and gather worktrees per project.
Returns a list of plists (:project NAME :main-dir DIR :worktrees LIST).
Projects that are not git repos are omitted.  Each entry of `:worktrees'
is the plist returned by `--git-list-worktrees'."
  (let (results)
    (dolist (entry claude-code-projects-list)
      (let* ((project (car entry))
             (dir (and (cdr entry) (expand-file-name (cdr entry)))))
        (when (and dir (file-directory-p dir)
                   (claude-code-projects--git-repo-p dir))
          (push (list :project project
                      :main-dir dir
                      :worktrees (claude-code-projects--git-list-worktrees dir))
                results))))
    (nreverse results)))

;;;###autoload
(defun claude-code-list-worktrees ()
  "Display all git worktrees for projects in `claude-code-projects-list'."
  (interactive)
  (claude-code-projects--gc-sessions)
  (let ((all (claude-code-projects--collect-all-worktrees)))
    (with-output-to-temp-buffer "*claude-worktrees*"
      (princ "Claude Code worktrees\n")
      (princ "=====================\n\n")
      (if (null all)
          (princ "No git-repo projects found.\n")
        (dolist (proj all)
          (princ (format "## %s  (%s)\n"
                         (plist-get proj :project)
                         (plist-get proj :main-dir)))
          (dolist (wt (plist-get proj :worktrees))
            (let* ((path (plist-get wt :path))
                   (branch (or (plist-get wt :branch) "(detached)"))
                   (main-p (plist-get wt :main-p))
                   (sess (claude-code-projects--session-for-worktree path))
                   (dirty (claude-code-projects--git-worktree-dirty-p path)))
              (princ (format "  %s [%s]%s%s%s\n    %s\n"
                             branch
                             (if main-p "main" "worktree")
                             (if sess "  ●session" "")
                             (if dirty "  ⚠dirty" "")
                             (if (and (not main-p) (not sess)) "  (orphan)" "")
                             path))))
          (princ "\n"))))))

;;;###autoload
(defun claude-code-open-worktree ()
  "Pick an existing worktree (across projects) and start a session in it.
Worktrees that already have a live session are filtered out, as is the
main worktree."
  (interactive)
  (claude-code-projects--gc-sessions)
  (let* ((all (claude-code-projects--collect-all-worktrees))
         (candidates nil))
    (dolist (proj all)
      (dolist (wt (plist-get proj :worktrees))
        (let ((path (plist-get wt :path)))
          (unless (or (plist-get wt :main-p)
                      (claude-code-projects--session-for-worktree path))
            (push (cons (format "%s [%s]  %s"
                                (plist-get proj :project)
                                (or (plist-get wt :branch) "(detached)")
                                path)
                        (list :project (plist-get proj :project)
                              :directory path
                              :branch (plist-get wt :branch)))
                  candidates)))))
    (cond
     ((null candidates)
      (message "No idle worktrees available"))
     (t
      (let* ((pick (completing-read "Open worktree: " candidates nil t))
             (info (cdr (assoc pick candidates))))
        (claude-code-projects--start-session-in-dir
         (plist-get info :project)
         (plist-get info :directory)
         t (plist-get info :branch)))))))

(defun claude-code-projects--pick-session-interactively (prompt)
  "Read a session plist via `completing-read' using PROMPT."
  (let* ((sessions (claude-code-projects--gc-sessions))
         (choices (mapcar (lambda (s)
                            (cons (format "%s - %s"
                                          (claude-code-projects--session-display-name s)
                                          (plist-get s :buffer-name))
                                  s))
                          sessions)))
    (cond
     ((null choices) (user-error "No active Claude Code sessions"))
     (t (let ((pick (completing-read prompt choices nil t)))
          (cdr (assoc pick choices)))))))

(defun claude-code-projects--maybe-remove-worktree-for-session (session)
  "Offer to remove the worktree (if any) belonging to SESSION."
  (when (plist-get session :worktree-p)
    (let* ((dir (plist-get session :directory))
           (project (plist-get session :project))
           (entry (assoc project claude-code-projects-list))
           (repo-dir (and entry (expand-file-name (cdr entry)))))
      (when (and repo-dir
                 (y-or-n-p (format "Remove worktree at %s? " dir)))
        (let ((dirty (claude-code-projects--git-worktree-dirty-p dir)))
          (cond
           (dirty
            (when (yes-or-no-p
                   (format "⚠️  %s has UNCOMMITTED CHANGES.  Force remove anyway? "
                           dir))
              (claude-code-projects--git-remove-worktree repo-dir dir t)
              (when claude-code-projects-use-cage
                (claude-code-projects--cage-remove-worktree-path dir))
              (message "Force-removed worktree: %s" dir)))
           (t
            (claude-code-projects--git-remove-worktree repo-dir dir nil)
            (when claude-code-projects-use-cage
              (claude-code-projects--cage-remove-worktree-path dir))
            (message "Removed worktree: %s" dir))))))))

;;;###autoload
(defun claude-code-kill-session ()
  "Kill the Claude Code session for the current buffer (or pick one).
If invoked from a Claude Code session buffer, that session is targeted.
Otherwise the user picks via completing-read.  When the session was
running in a worktree, the user is asked whether to remove it; sessions
with uncommitted changes require explicit force confirmation."
  (interactive)
  (let* ((sess (or (claude-code-projects--session-by-buffer (current-buffer))
                   (claude-code-projects--pick-session-interactively
                    "Kill session: "))))
    (let ((buf (get-buffer (plist-get sess :buffer-name))))
      (when (buffer-live-p buf)
        (kill-buffer buf)))
    (claude-code-projects--maybe-remove-worktree-for-session sess)
    (setq claude-code-projects-sessions
          (cl-remove sess claude-code-projects-sessions :test #'equal))
    (message "Killed session: %s"
             (claude-code-projects--session-display-name sess))))

;;;###autoload
(defun claude-code-cleanup-all-worktrees ()
  "Find and optionally remove orphaned worktrees across all projects.
A worktree is considered orphaned when no live Claude Code session points
to it.  Worktrees with uncommitted changes are flagged and require
individual force confirmation."
  (interactive)
  (claude-code-projects--gc-sessions)
  (let* ((all (claude-code-projects--collect-all-worktrees))
         (orphans nil))
    (dolist (proj all)
      (dolist (wt (plist-get proj :worktrees))
        (let ((path (plist-get wt :path)))
          (unless (or (plist-get wt :main-p)
                      (claude-code-projects--session-for-worktree path))
            (push (list :project (plist-get proj :project)
                        :repo-dir (plist-get proj :main-dir)
                        :path path
                        :branch (plist-get wt :branch)
                        :dirty (claude-code-projects--git-worktree-dirty-p path))
                  orphans)))))
    (cond
     ((null orphans)
      (message "No orphaned worktrees found"))
     (t
      (with-output-to-temp-buffer "*claude-worktree-cleanup*"
        (princ (format "Found %d orphaned worktree(s):\n\n" (length orphans)))
        (dolist (o orphans)
          (princ (format "  [%s] %s%s\n    %s\n"
                         (plist-get o :project)
                         (or (plist-get o :branch) "(detached)")
                         (if (plist-get o :dirty) "  ⚠️ HAS UNCOMMITTED CHANGES" "")
                         (plist-get o :path)))))
      (when (yes-or-no-p (format "Clean up %d orphaned worktree(s)? "
                                 (length orphans)))
        (let ((removed 0) (skipped 0))
          (dolist (o orphans)
            (let ((path (plist-get o :path))
                  (repo-dir (plist-get o :repo-dir))
                  (dirty (plist-get o :dirty)))
              (cond
               ((and dirty
                     (not (yes-or-no-p
                           (format "Force remove DIRTY worktree at %s? " path))))
                (cl-incf skipped))
               (t
                (claude-code-projects--git-remove-worktree repo-dir path dirty)
                (when claude-code-projects-use-cage
                  (claude-code-projects--cage-remove-worktree-path path))
                (cl-incf removed)))))
          (message "Cleanup complete: %d removed, %d skipped" removed skipped)))))))

;;; ---------------------------------------------------------------------------
;;; Cage re-sync + crash recovery (Phase 7)
;;; ---------------------------------------------------------------------------

(defun claude-code-projects--cage-resync ()
  "Reconcile cage worktree entries with currently live sessions.
- Cage entries pointing to no live session are REMOVED (cage entry only;
  the worktree directory on disk is preserved so uncommitted work is safe).
- Live sessions whose worktree path is missing from cage have their entry
  added (defends against `bin/update-cage-config' wiping the marker block).
Path comparison uses canonical form so symlink differences don't matter.
Returns a cons (REMOVED . ADDED) of counts."
  (claude-code-projects--gc-sessions)
  (let* ((file (claude-code-projects--cage-config-path))
         (current (and (file-exists-p file)
                       (claude-code-projects--cage-list-worktree-paths)))
         (desired (mapcar (lambda (s)
                            (plist-get s :directory))
                          (cl-remove-if-not
                           (lambda (s)
                             (and (claude-code-projects--session-live-p s)
                                  (plist-get s :worktree-p)))
                           claude-code-projects-sessions)))
         (canon-desired (mapcar #'claude-code-projects--canonical-path desired))
         (removed 0) (added 0))
    (when (file-exists-p file)
      (dolist (path current)
        (unless (member (claude-code-projects--canonical-path path)
                        canon-desired)
          (when (claude-code-projects--cage-remove-worktree-path path)
            (cl-incf removed))))
      (dolist (path desired)
        (let ((canon (claude-code-projects--canonical-path path)))
          (unless (member canon
                          (mapcar #'claude-code-projects--canonical-path
                                  (claude-code-projects--cage-list-worktree-paths)))
            (when (claude-code-projects--cage-add-worktree-path path)
              (cl-incf added))))))
    (cons removed added)))

(defun claude-code-projects--auto-cleanup-cage-on-startup ()
  "Idle-timer entry point: clean up stale cage worktree entries.
Runs once a few seconds after Emacs init.  NEVER deletes worktree
directories — only the cage entries that point to them."
  (when (file-exists-p (claude-code-projects--cage-config-path))
    (pcase-let ((`(,removed . ,added) (claude-code-projects--cage-resync)))
      (when (or (> removed 0) (> added 0))
        (message
         "claude-code-projects: cage resync: %d removed, %d added (worktree dirs preserved)"
         removed added)))))

;; Defense in depth: also re-sync before creating any new worktree.
(advice-add 'claude-code-projects--maybe-create-worktree :before
            (lambda (&rest _)
              (when (file-exists-p (claude-code-projects--cage-config-path))
                (claude-code-projects--cage-resync))))

;; Schedule the startup cleanup (5s idle, fires once).
(run-with-idle-timer 30 nil #'claude-code-projects--auto-cleanup-cage-on-startup)

(provide 'claude-code-projects)
;;; claude-code-projects.el ends here
