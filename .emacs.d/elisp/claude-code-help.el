;;; claude-code-help.el --- Interactive help for Claude Code workflows -*- lexical-binding: t; -*-

;; Copyright (C) 2026

;; Author: Your Name
;; Keywords: tools, help
;; Version: 1.0.0
;; Package-Requires: ((emacs "25.1"))

;;; Commentary:

;; This package provides an interactive help system for Claude Code workflows.
;; It displays recommended workflows for different development tasks such as
;; feature development, bug fixing, refactoring, UI development, etc.
;;
;; Usage:
;;   M-x claude-code-help-flow
;;   or
;;   C-c C-? f (if key binding is configured)

;;; Code:

(require 'claude-code-help-content)
(require 'outline)

;;; Customization

(defgroup claude-code-help nil
  "Interactive help for Claude Code workflows."
  :group 'tools
  :prefix "claude-code-help-")

(defface claude-code-help-title-face
  '((t :inherit font-lock-keyword-face :weight bold :height 1.2))
  "Face for workflow titles."
  :group 'claude-code-help)

(defface claude-code-help-description-face
  '((t :inherit font-lock-doc-face :slant italic))
  "Face for workflow descriptions."
  :group 'claude-code-help)

(defface claude-code-help-step-face
  '((t :inherit default))
  "Face for workflow steps."
  :group 'claude-code-help)

(defface claude-code-help-command-face
  '((t :inherit font-lock-string-face))
  "Face for commands."
  :group 'claude-code-help)

(defface claude-code-help-section-face
  '((t :inherit font-lock-function-name-face :weight bold))
  "Face for section headers."
  :group 'claude-code-help)

;;; Mode definition

(defvar claude-code-help-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "q") 'quit-window)
    (define-key map (kbd "n") 'claude-code-help-next-section)
    (define-key map (kbd "p") 'claude-code-help-previous-section)
    (define-key map (kbd "TAB") 'claude-code-help-toggle-section)
    (define-key map (kbd "RET") 'claude-code-help-select-workflow)
    (define-key map (kbd "?") 'claude-code-help-show-keybindings)
    map)
  "Keymap for `claude-code-help-mode'.")

(define-derived-mode claude-code-help-mode special-mode "Claude-Help"
  "Major mode for Claude Code workflow help.

\\{claude-code-help-mode-map}"
  (setq buffer-read-only t)
  (setq truncate-lines nil)
  (visual-line-mode 1))

;;; Navigation functions

(defun claude-code-help-next-section ()
  "Move to the next section."
  (interactive)
  (let ((pos (next-single-property-change (point) 'section-start)))
    (when pos
      (goto-char pos))))

(defun claude-code-help-previous-section ()
  "Move to the previous section."
  (interactive)
  (let ((pos (previous-single-property-change (point) 'section-start)))
    (when pos
      (goto-char pos))))

(defun claude-code-help-toggle-section ()
  "Toggle visibility of current section."
  (interactive)
  (let ((inhibit-read-only t))
    (outline-toggle-children)))

(defun claude-code-help-select-workflow ()
  "Select and display detailed workflow at point."
  (interactive)
  (let ((workflow-id (get-text-property (point) 'workflow-id)))
    (when workflow-id
      (claude-code-help-show-workflow workflow-id))))

(defun claude-code-help-show-keybindings ()
  "Show available keybindings."
  (interactive)
  (message "q: Quit | n/p: Next/Prev section | TAB: Toggle | RET: Select | ?: Help"))

;;; Rendering functions

(defun claude-code-help--insert-header ()
  "Insert the help buffer header."
  (insert (propertize "═══════════════════════════════════════════════════════════════════════════\n"
                      'face 'claude-code-help-section-face))
  (insert (propertize "                    Claude Code Workflow Guide\n"
                      'face 'claude-code-help-title-face))
  (insert (propertize "═══════════════════════════════════════════════════════════════════════════\n\n"
                      'face 'claude-code-help-section-face))
  (insert (propertize "Claude Codeを効率的に使うためのワークフローガイドです。\n"
                      'face 'claude-code-help-description-face))
  (insert (propertize "各フローを選択（RET）して詳細を確認するか、このまま全体を閲覧できます。\n\n"
                      'face 'claude-code-help-description-face))
  (insert (propertize "Keybindings: q=閉じる | n/p=次/前 | TAB=折畳 | RET=選択 | ?=ヘルプ\n\n"
                      'face 'font-lock-comment-face)))

(defun claude-code-help--insert-workflow (workflow-data)
  "Insert a single workflow section from WORKFLOW-DATA."
  (let* ((title (plist-get (cdr workflow-data) :title))
         (description (plist-get (cdr workflow-data) :description))
         (steps (plist-get (cdr workflow-data) :steps))
         (workflow-id (car workflow-data)))

    ;; Title with section marker
    (insert (propertize (format "* %s\n" title)
                        'face 'claude-code-help-title-face
                        'workflow-id workflow-id
                        'section-start t))

    ;; Description
    (when description
      (insert (propertize (format "  %s\n\n" description)
                          'face 'claude-code-help-description-face)))

    ;; Steps
    (dolist (step steps)
      (cond
       ;; Command lines (contain ":  " or specific patterns)
       ((or (string-match-p "^[[:space:]]*-.*:" step)
            (string-match-p "コマンド:" step)
            (string-match-p "アプローチ:" step))
        (insert (propertize (format "  %s\n" step)
                            'face 'claude-code-help-command-face)))
       ;; Section headers (contain "【" or start with capital letters)
       ((or (string-match-p "【.*】" step)
            (string-match-p "^[A-Z]" step))
        (insert (propertize (format "  %s\n" step)
                            'face 'claude-code-help-section-face)))
       ;; Regular steps
       (t
        (insert (propertize (format "  %s\n" step)
                            'face 'claude-code-help-step-face)))))

    (insert "\n")))

(defun claude-code-help--insert-command-reference ()
  "Insert command reference section."
  (insert (propertize "\n───────────────────────────────────────────────────────────────────────────\n"
                      'face 'claude-code-help-section-face))
  (insert (propertize "                    主要コマンドリファレンス\n"
                      'face 'claude-code-help-title-face))
  (insert (propertize "───────────────────────────────────────────────────────────────────────────\n\n"
                      'face 'claude-code-help-section-face))

  (dolist (category claude-code-key-commands)
    (let ((cat-name (plist-get category :category))
          (commands (plist-get category :commands)))
      (insert (propertize (format "** %s\n" cat-name)
                          'face 'claude-code-help-section-face))
      (dolist (cmd commands)
        (insert (propertize (format "   %-40s  %s\n"
                                    (car cmd)
                                    (cdr cmd))
                            'face 'claude-code-help-step-face)))
      (insert "\n"))))

(defun claude-code-help--render-content ()
  "Render the complete help content in current buffer."
  (let ((inhibit-read-only t))
    (erase-buffer)

    ;; Header
    (claude-code-help--insert-header)

    ;; Workflows
    (insert (propertize "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
                        'face 'claude-code-help-section-face))
    (insert (propertize "                           ワークフロー一覧\n"
                        'face 'claude-code-help-title-face))
    (insert (propertize "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n"
                        'face 'claude-code-help-section-face))

    (dolist (workflow claude-code-workflows)
      (claude-code-help--insert-workflow workflow))

    ;; Command reference
    (claude-code-help--insert-command-reference)

    ;; Footer
    (insert (propertize "\n═══════════════════════════════════════════════════════════════════════════\n"
                        'face 'claude-code-help-section-face))
    (insert (propertize "                         Happy Coding with Claude!\n"
                        'face 'claude-code-help-description-face))
    (insert (propertize "═══════════════════════════════════════════════════════════════════════════\n"
                        'face 'claude-code-help-section-face))

    (goto-char (point-min))))

(defun claude-code-help-show-workflow (workflow-id)
  "Show detailed view of a specific workflow identified by WORKFLOW-ID."
  (let* ((workflow (assoc workflow-id claude-code-workflows))
         (buf (get-buffer-create (format "*Claude Workflow: %s*" workflow-id))))
    (with-current-buffer buf
      (claude-code-help-mode)
      (let ((inhibit-read-only t))
        (erase-buffer)
        (claude-code-help--insert-header)
        (claude-code-help--insert-workflow workflow)
        (insert "\n\nPress 'q' to close this buffer.\n")
        (goto-char (point-min))))
    (pop-to-buffer buf)))

;;; Main entry point

;;;###autoload
(defun claude-code-help-flow ()
  "Display Claude Code workflow help in a dedicated buffer.

This command shows an interactive guide for using Claude Code effectively,
including recommended workflows for different development tasks such as:
- Feature development
- Bug fixing
- Refactoring
- UI development
- Code review
- Documentation

Navigation:
  q     - Quit and close the help buffer
  n/p   - Move to next/previous section
  TAB   - Toggle section folding
  RET   - Select and view detailed workflow
  ?     - Show keybindings help"
  (interactive)
  (let ((buf (get-buffer-create "*Claude Code Workflows*")))
    (with-current-buffer buf
      (claude-code-help-mode)
      (claude-code-help--render-content))
    (pop-to-buffer buf)))

;;;###autoload
(defun claude-code-help-quick-reference ()
  "Display a quick reference of Claude Code commands."
  (interactive)
  (let ((buf (get-buffer-create "*Claude Code Quick Reference*")))
    (with-current-buffer buf
      (claude-code-help-mode)
      (let ((inhibit-read-only t))
        (erase-buffer)
        (claude-code-help--insert-header)
        (claude-code-help--insert-command-reference)
        (goto-char (point-min))))
    (pop-to-buffer buf)))

(provide 'claude-code-help)
;;; claude-code-help.el ends here
