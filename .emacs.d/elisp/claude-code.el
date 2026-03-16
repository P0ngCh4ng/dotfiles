;;; claude-code.el --- Claude Code integration for Emacs -*- lexical-binding: t; -*-

;;; Commentary:
;; Emacs内でClaude Codeを実行するためのパッケージ
;; vterm を使用して高性能なターミナル統合を提供

;;; Code:

(require 'cl-lib)
(require 'vterm)
(require 'projectile nil t)  ;; projectileはオプショナル

(defgroup claude-code nil
  "Claude Code integration settings."
  :group 'tools
  :prefix "claude-code-")

(defcustom claude-code-command
  "cage -config \"$HOME/.config/cage/presets.yaml\" claude --dangerously-skip-permissions"
  "Command to launch Claude Code."
  :type 'string
  :group 'claude-code)

(defcustom claude-code-projects
  '(("dotfiles" . "~/dotfiles")
    ("pon" . "~/pon")
    ("sokko" . "~/sokko")
    ("chatclinic" . "~/chatclinic")
    ("AutomationVideo" . "~/AutomationVideo")
    ("mcpCreate" . "~/mcpCreate"))
  "List of frequently used projects for Claude Code."
  :type '(alist :key-type string :value-type string)
  :group 'claude-code)

(defvar claude-code-buffer-name-format "*claude-code-%s*"
  "Format for Claude Code buffer names.")

(defvar claude-code-session-counter 0
  "Counter for unnamed sessions.")

;;; Helper Functions

(defun claude-code--get-project-root ()
  "Get project root directory using projectile or .git detection."
  (or (and (featurep 'projectile)
           (projectile-project-root))
      (locate-dominating-file default-directory ".git")
      default-directory))

(defun claude-code--get-project-name (project-root)
  "Get project name from PROJECT-ROOT."
  (file-name-nondirectory (directory-file-name (expand-file-name project-root))))

(defun claude-code--start-in-directory (directory name)
  "Start Claude Code in DIRECTORY with session NAME."
  (let* ((buffer-name (format claude-code-buffer-name-format name))
         (default-directory (expand-file-name directory)))
    (if (get-buffer buffer-name)
        (switch-to-buffer buffer-name)
      (let ((vterm-shell claude-code-command))
        (vterm buffer-name)))))

(defun claude-code--list-sessions ()
  "Return list of active Claude Code session buffers."
  (cl-remove-if-not
   (lambda (b)
     (string-match-p "\\*claude-code-.*\\*" (buffer-name b)))
   (buffer-list)))

;;; Interactive Commands

;;;###autoload
(defun claude-code-start-auto ()
  "Start Claude Code in current project (auto-detected)."
  (interactive)
  (let* ((project-root (claude-code--get-project-root))
         (project-name (claude-code--get-project-name project-root)))
    (claude-code--start-in-directory project-root project-name)))

;;;###autoload
(defun claude-code-start-projectile ()
  "Start Claude Code using projectile project detection."
  (interactive)
  (if (not (featurep 'projectile))
      (message "Projectile is not available. Use claude-code-start-auto instead.")
    (let* ((project-root (projectile-project-root))
           (project-name (projectile-project-name)))
      (if project-root
          (claude-code--start-in-directory project-root project-name)
        (message "Not in a projectile project")))))

;;;###autoload
(defun claude-code-select-project ()
  "Select project from predefined list and start Claude Code."
  (interactive)
  (let* ((project (completing-read "Project: " claude-code-projects nil t))
         (dir (cdr (assoc project claude-code-projects))))
    (if dir
        (claude-code--start-in-directory dir project)
      (message "Project not found: %s" project))))

;;;###autoload
(defun claude-code-start-manual ()
  "Start Claude Code with manual session name input."
  (interactive)
  (let ((session-name (read-string "Session name (empty for auto): ")))
    (if (string-empty-p session-name)
        (setq session-name (format "session-%d" (cl-incf claude-code-session-counter))))
    (claude-code--start-in-directory default-directory session-name)))

;;;###autoload
(defun claude-code-switch-session ()
  "Switch between active Claude Code sessions."
  (interactive)
  (let* ((buffers (claude-code--list-sessions))
         (names (mapcar #'buffer-name buffers)))
    (if names
        (switch-to-buffer
         (completing-read "Switch to session: " names nil t))
      (message "No Claude Code sessions found"))))

;;;###autoload
(defun claude-code-kill-session ()
  "Kill a Claude Code session."
  (interactive)
  (let* ((buffers (claude-code--list-sessions))
         (names (mapcar #'buffer-name buffers)))
    (if names
        (let ((buffer-name (completing-read "Kill session: " names nil t)))
          (kill-buffer buffer-name)
          (message "Killed session: %s" buffer-name))
      (message "No Claude Code sessions found"))))

;;;###autoload
(defun claude-code-rename-session ()
  "Rename current Claude Code session."
  (interactive)
  (when (string-match-p "\\*claude-code-.*\\*" (buffer-name))
    (let ((new-name (read-string "New session name: ")))
      (unless (string-empty-p new-name)
        (rename-buffer (format claude-code-buffer-name-format new-name))))))

;;; Keybindings

(defvar claude-code-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-c c s") 'claude-code-start-auto)
    (define-key map (kbd "C-c c p") 'claude-code-select-project)
    (define-key map (kbd "C-c c P") 'claude-code-start-projectile)
    (define-key map (kbd "C-c c m") 'claude-code-start-manual)
    (define-key map (kbd "C-c c w") 'claude-code-switch-session)
    (define-key map (kbd "C-c c k") 'claude-code-kill-session)
    (define-key map (kbd "C-c c r") 'claude-code-rename-session)
    map)
  "Keymap for Claude Code commands.")

;;;###autoload
(define-minor-mode claude-code-mode
  "Minor mode for Claude Code integration."
  :lighter " CC"
  :keymap claude-code-mode-map
  :global t)

(provide 'claude-code)
;;; claude-code.el ends here
