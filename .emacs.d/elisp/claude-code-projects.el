;;; claude-code-projects.el --- Project shortcuts for Claude Code -*- lexical-binding: t; -*-

;;; Commentary:
;; Extends the official claude-code package with:
;; - Predefined project shortcuts
;; - Cage integration for advanced configuration
;; - Multiple session management per project
;; - Session switching and renaming

;;; Code:

(require 'cl-lib)

;; Forward declarations from claude-code-core
(declare-function claude-code-run "claude-code-core" ())

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
  "Get the Claude Code launch command (with or without cage)."
  (if claude-code-projects-use-cage
      (format "cage -config \"%s\" claude --dangerously-skip-permissions"
              (expand-file-name claude-code-projects-cage-config))
    claude-code-executable))

;;;###autoload
(defun claude-code-select-project ()
  "Select a project from predefined list and start Claude Code."
  (interactive)
  (let* ((project (completing-read "Select project: " claude-code-projects-list nil t))
         (dir (cdr (assoc project claude-code-projects-list))))
    (if dir
        (let ((default-directory (expand-file-name dir))
              (claude-code-executable (claude-code-projects--get-command)))
          (claude-code-run)
          ;; Track session
          (let ((buffer-name (buffer-name)))
            (add-to-list 'claude-code-projects-sessions
                         (cons project buffer-name))))
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
