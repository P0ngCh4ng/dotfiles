;;; claude-code-projects.el --- Project shortcuts for Claude Code -*- lexical-binding: t; -*-

;;; Commentary:
;; Extends the official claude-code package with:
;; - Predefined project shortcuts
;; - Cage integration for advanced configuration
;; - Multiple session management per project
;; - Session switching and renaming
;; - Fix for non-projectile directories (empty directories without .git)

;;; Code:

(require 'cl-lib)

;; claude-codeパッケージをロード（遅延ロード対応）
;; C-c C-pが押されたときに、必要に応じてclaude-codeをロードする
(require 'claude-code nil t)

;; Forward declarations from claude-code-core
(declare-function claude-code-run "claude-code-core" ())
(defvar claude-code-executable)

;;; Fix for non-projectile directories
;; claude-code-coreはprojectile-project-rootに依存しているが、
;; .gitなどのマーカーがないディレクトリではnilを返すため、
;; default-directoryをフォールバックとして使用するようアドバイスする

(defun claude-code-projects--safe-project-root ()
  "Get project root with fallback to default-directory.
Handles cases where projectile-project-root returns nil."
  (or (and (fboundp 'projectile-project-root)
           (projectile-project-root))
      default-directory))

(with-eval-after-load 'claude-code-core
  (defun claude-code-projects--buffer-name-advice (orig-fun)
    "Advice for claude-code-buffer-name to handle non-projectile directories."
    (let* ((project-root (claude-code-projects--safe-project-root))
           (normalized-root (when project-root
                             (directory-file-name (expand-file-name project-root)))))
      (when normalized-root
        (format "*claude:%s*" normalized-root))))

  (advice-add 'claude-code-buffer-name :around
              (lambda (orig-fun &rest args)
                (or (apply orig-fun args)
                    (claude-code-projects--buffer-name-advice orig-fun))))

  (defun claude-code-projects--run-advice (orig-fun &rest args)
    "Advice for claude-code-run to handle non-projectile directories."
    (let* ((project-root (claude-code-projects--safe-project-root))
           (default-directory (expand-file-name project-root)))
      (apply orig-fun args)))

  (advice-add 'claude-code-run :around #'claude-code-projects--run-advice))

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
  "Whether to use cage for launching Claude Code.
When non-nil, uses cage with presets configuration."
  :type 'boolean
  :group 'claude-code-projects)

(defcustom claude-code-projects-cage-config
  "~/.config/cage/presets.yaml"
  "Path to cage configuration file."
  :type 'file
  :group 'claude-code-projects)

(defvar claude-code-projects-sessions nil
  "List of active Claude Code sessions.
Each entry is (PROJECT-NAME . BUFFER-NAME).")

;;; Cage Integration

(defun claude-code-projects--get-command ()
  "Get the Claude Code launch command (with or without cage).
Automatically disables cage if already running inside cage (IN_CAGE=1)
to prevent nested cage issues."
  (let ((already-in-cage (getenv "IN_CAGE")))
    (if (and claude-code-projects-use-cage (not already-in-cage))
        (format "env CLAUDE_CODE_DISABLE_ITERM2=1 cage -config \"%s\" claude --dangerously-skip-permissions"
                (expand-file-name claude-code-projects-cage-config))
      (if (boundp 'claude-code-executable)
          (format "env CLAUDE_CODE_DISABLE_ITERM2=1 %s --dangerously-skip-permissions" claude-code-executable)
        "env CLAUDE_CODE_DISABLE_ITERM2=1 claude --dangerously-skip-permissions"))))

;;;###autoload
(defun claude-code-select-project ()
  "Select a project from predefined list and start Claude Code."
  (interactive)
  (let* ((project (completing-read "Select project: " claude-code-projects-list nil t))
         (dir (cdr (assoc project claude-code-projects-list))))
    (if dir
        (let ((default-directory (expand-file-name dir))
              (claude-code-executable (claude-code-projects--get-command))
              (project-dir (expand-file-name dir)))
          (claude-code-run)
          ;; Track session
          (let ((buffer-name (buffer-name)))
            (add-to-list 'claude-code-projects-sessions
                         (cons project buffer-name)))
          ;; cage使用時はworking directoryが正しく設定されないため、
          ;; vterm起動後に明示的にcdコマンドを送信
          (when claude-code-projects-use-cage
            (run-with-timer 1.5 nil
                           (lambda (dir buf-name)
                             (when-let ((buf (get-buffer buf-name)))
                               (with-current-buffer buf
                                 (require 'vterm)
                                 (vterm-send-string (format "cd \"%s\"" dir))
                                 (vterm-send-return))))
                           project-dir buffer-name)))
      (user-error "Project not found: %s" project))))

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

;;; Session Management

;;;###autoload
(defun claude-code-list-sessions ()
  "List all active Claude Code sessions."
  (interactive)
  (let ((sessions (cl-remove-if-not
                   (lambda (pair)
                     (buffer-live-p (get-buffer (cdr pair))))
                   claude-code-projects-sessions)))
    (setq claude-code-projects-sessions sessions)
    (if sessions
        (message "Active sessions: %s"
                 (mapconcat (lambda (pair)
                             (format "%s (%s)" (car pair) (cdr pair)))
                           sessions ", "))
      (message "No active Claude Code sessions"))))

;;;###autoload
(defun claude-code-switch-session ()
  "Switch to a Claude Code session."
  (interactive)
  (let* ((sessions (cl-remove-if-not
                    (lambda (pair)
                      (buffer-live-p (get-buffer (cdr pair))))
                    claude-code-projects-sessions))
         (choices (mapcar (lambda (pair)
                           (format "%s - %s" (car pair) (cdr pair)))
                         sessions))
         (selected (completing-read "Switch to session: " choices nil t)))
    (when selected
      (let* ((buffer-name (cadr (split-string selected " - ")))
             (buffer (get-buffer buffer-name)))
        (if buffer
            (switch-to-buffer buffer)
          (message "Session buffer no longer exists"))))))

;;;###autoload
(defun claude-code-kill-all-sessions ()
  "Kill all Claude Code sessions."
  (interactive)
  (when (yes-or-no-p "Kill all Claude Code sessions? ")
    (dolist (pair claude-code-projects-sessions)
      (when-let ((buffer (get-buffer (cdr pair))))
        (kill-buffer buffer)))
    (setq claude-code-projects-sessions nil)
    (message "All Claude Code sessions killed")))

;;;###autoload
(defun claude-code-toggle-cage ()
  "Toggle cage usage on/off."
  (interactive)
  (setq claude-code-projects-use-cage (not claude-code-projects-use-cage))
  (message "Cage integration: %s"
           (if claude-code-projects-use-cage "ENABLED" "DISABLED")))

(provide 'claude-code-projects)
;;; claude-code-projects.el ends here
