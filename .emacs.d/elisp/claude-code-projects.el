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
(require 'claude-code nil t)

;; Forward declarations
(declare-function claude-code-vterm-mode "claude-code-ui" ())
(defvar vterm-shell)

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
  "List of active Claude Code sessions.")

(defun claude-code-projects--get-command ()
  "Get the Claude Code launch command."
  (if claude-code-projects-use-cage
      (format "cage -config %s -preset claude-code -- bash -c 'env CLAUDE_CODE_DISABLE_ITERM2=1 claude --dangerously-skip-permissions'"
              (shell-quote-argument (expand-file-name claude-code-projects-cage-config)))
    "env CLAUDE_CODE_DISABLE_ITERM2=1 claude --dangerously-skip-permissions"))

;;;###autoload
(defun claude-code-select-project ()
  "Select a project from predefined list and start Claude Code."
  (interactive)
  (let* ((project (completing-read "Select project: " claude-code-projects-list nil t))
         (dir (cdr (assoc project claude-code-projects-list))))
    (cond
     ((not dir)
      (user-error "Project directory not configured for: %s" project))
     ((string-empty-p dir)
      (user-error "Project directory is empty for: %s" project))
     (t
      (let* ((expanded-dir (expand-file-name dir))
             (project-dir expanded-dir)
             (normalized-root (directory-file-name expanded-dir))
             (buffer-name (format "*claude:%s*" normalized-root))
             (existing-buffer (get-buffer buffer-name)))
        (unless (file-directory-p expanded-dir)
          (user-error "Directory does not exist: %s" expanded-dir))
        ;; If buffer exists, just switch to it
        (if (and existing-buffer (buffer-live-p existing-buffer))
            (progn
              (switch-to-buffer-other-window buffer-name)
              (message "Switched to existing session: %s" project))
          ;; Create new session
          (let ((command (claude-code-projects--get-command))
                (original-vterm-shell (and (boundp 'vterm-shell) vterm-shell))
                (original-default-directory default-directory))
            (setq default-directory expanded-dir)
            (setq vterm-shell command)
            (unwind-protect
                (progn
                  (let ((buf (get-buffer-create buffer-name)))
                    (with-current-buffer buf
                      (require 'claude-code-ui)
                      (claude-code-vterm-mode))
                    (switch-to-buffer-other-window buffer-name)
                    (add-to-list 'claude-code-projects-sessions
                                 (cons project buffer-name))
                    (when claude-code-projects-use-cage
                      (run-with-timer 1.5 nil
                                     (lambda (dir buf-name)
                                       (when-let ((buf (get-buffer buf-name)))
                                         (with-current-buffer buf
                                           (require 'vterm)
                                           (vterm-send-string (format "cd \"%s\"" dir))
                                           (vterm-send-return))))
                                     project-dir buffer-name))
                    (message "Started Claude Code session: %s" project)))
              (setq vterm-shell original-vterm-shell)
              (setq default-directory original-default-directory)))))))))

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
