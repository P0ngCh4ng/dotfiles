;;; verification-helpers.el --- Emacs configuration verification helpers -*- lexical-binding: t; -*-

;;; Commentary:
;; Helper functions for verifying Emacs configuration
;; Used by Claude Code's emacs-verifier system

;;; Code:

(defun verification-helpers-dump-messages ()
  "Dump the entire *Messages* buffer to stdout.
This is used by the verification system to capture all warnings and errors."
  (interactive)
  (with-current-buffer "*Messages*"
    (princ (buffer-string))))

(defun verification-helpers-check-undefined-functions ()
  "Check for undefined function warnings in the current session.
Returns a list of undefined function names."
  (interactive)
  (let ((undefined-funcs '()))
    (with-current-buffer "*Messages*"
      (save-excursion
        (goto-char (point-min))
        (while (re-search-forward "the function [`']\\([^']+\\)['] is not known" nil t)
          (push (match-string 1) undefined-funcs))))
    (when (called-interactively-p 'any)
      (message "Undefined functions: %s" undefined-funcs))
    undefined-funcs))

(defun verification-helpers-check-undefined-variables ()
  "Check for undefined variable warnings in the current session.
Returns a list of undefined variable names."
  (interactive)
  (let ((undefined-vars '()))
    (with-current-buffer "*Messages*"
      (save-excursion
        (goto-char (point-min))
        (while (re-search-forward "assignment to free variable [`']\\([^']+\\)[']" nil t)
          (push (match-string 1) undefined-vars))))
    (when (called-interactively-p 'any)
      (message "Undefined variables: %s" undefined-vars))
    undefined-vars))

(defun verification-helpers-check-obsolete-functions ()
  "Check for obsolete function warnings in the current session.
Returns an alist of (obsolete-func . replacement) pairs."
  (interactive)
  (let ((obsolete-funcs '()))
    (with-current-buffer "*Messages*"
      (save-excursion
        (goto-char (point-min))
        (while (re-search-forward "[\`']\\([^']+\\)['] is an obsolete function.*use [`']\\([^']+\\)[']" nil t)
          (push (cons (match-string 1) (match-string 2)) obsolete-funcs))))
    (when (called-interactively-p 'any)
      (message "Obsolete functions: %s" obsolete-funcs))
    obsolete-funcs))

(defun verification-helpers-package-status ()
  "Check package system status and return diagnostics.
Returns a plist with package information."
  (interactive)
  (require 'package)
  (let ((status (list :initialized (bound-and-true-p package--initialized)
                      :archives (mapcar #'car package-archives)
                      :activated-count (length package-activated-list))))
    (when (called-interactively-p 'any)
      (message "Package status: %s" status))
    status))

(defun verification-helpers-check-all ()
  "Run all verification checks and return a comprehensive report.
Returns a plist with all check results."
  (interactive)
  (let ((report (list :undefined-functions (verification-helpers-check-undefined-functions)
                      :undefined-variables (verification-helpers-check-undefined-variables)
                      :obsolete-functions (verification-helpers-check-obsolete-functions)
                      :package-status (verification-helpers-package-status)
                      :messages-length (with-current-buffer "*Messages*"
                                         (buffer-size)))))
    (when (called-interactively-p 'any)
      (message "Verification report: %s" report))
    report))

(defun verification-helpers-syntax-check-file (file)
  "Perform syntax check on FILE without loading it.
Returns non-nil if syntax is valid."
  (interactive "fFile to check: ")
  (condition-case err
      (progn
        (with-temp-buffer
          (insert-file-contents file)
          (emacs-lisp-mode)
          (check-parens))
        t)
    (error
     (message "Syntax error in %s: %s" file (error-message-string err))
     nil)))

(defun verification-helpers-count-parens ()
  "Count opening and closing parentheses in current buffer.
Returns (open . close) cons cell."
  (interactive)
  (save-excursion
    (goto-char (point-min))
    (let ((open 0)
          (close 0))
      (while (not (eobp))
        (skip-chars-forward "^()")
        (unless (eobp)
          (if (char-equal (char-after) ?\()
              (setq open (1+ open))
            (setq close (1+ close)))
          (forward-char)))
      (when (called-interactively-p 'any)
        (message "Parentheses: %d open, %d close" open close))
      (cons open close))))

(defun verification-helpers-find-unbalanced-parens ()
  "Find locations of unbalanced parentheses in current buffer.
Returns a list of positions where imbalance occurs."
  (interactive)
  (let ((unbalanced '())
        (depth 0))
    (save-excursion
      (goto-char (point-min))
      (while (not (eobp))
        (skip-chars-forward "^()")
        (unless (eobp)
          (if (char-equal (char-after) ?\()
              (setq depth (1+ depth))
            (setq depth (1- depth)))
          (when (< depth 0)
            (push (point) unbalanced)
            (setq depth 0))
          (forward-char))))
    (when (> depth 0)
      (push (point-max) unbalanced))
    (when (called-interactively-p 'any)
      (message "Unbalanced parentheses at: %s" (reverse unbalanced)))
    (reverse unbalanced)))

(defun verification-helpers-test-load-file (file)
  "Test loading FILE and capture any errors.
Returns (success-p . error-message)."
  (interactive "fFile to test: ")
  (condition-case err
      (progn
        (load-file file)
        (cons t nil))
    (error
     (cons nil (error-message-string err)))))

(provide 'verification-helpers)
;;; verification-helpers.el ends here
