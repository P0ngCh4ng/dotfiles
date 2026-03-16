# Task Completion Workflow

## For Emacs Configuration Changes
1. **Always backup first**: `cp ~/.emacs.d/init.el ~/.emacs.d/init.el.backup.$(date +%Y%m%d_%H%M%S)`
2. **Verification (run ALL)**:
   - Syntax check: `emacs --batch -l ~/.emacs.d/init.el 2>&1`
   - Runtime test: `emacs --eval "(run-with-timer 3 nil #'kill-emacs)" 2>&1`
   - Byte-compile: `emacs --batch --eval "(byte-compile-file \"~/.emacs.d/init.el\")" 2>&1`
   - Package check: `emacs --batch --eval "(progn (require 'package) (package-initialize))" 2>&1`
   - Messages buffer: `emacs --batch --eval "(progn (load-file \"~/.emacs.d/init.el\") (with-current-buffer \"*Messages*\" (princ (buffer-string))))" 2>&1`
3. **Fix ALL errors and warnings** - iterate until clean
4. **"Clean" = ZERO errors AND ZERO warnings**

## For Shell Configuration Changes
- Test zsh syntax: `zsh -n ~/.zshrc`
- Source and verify: `zsh -c 'source ~/.zshrc && echo OK'`
- No specific linting required

## For Makefile Changes
- Verify syntax: `make -n <target>`
- Test deployment: `make list` before `make deploy`

## General Workflow
- No automated testing framework
- Manual verification required
- Changes typically require shell restart: `exec $SHELL`
- For init scripts: re-run `make init` or specific script