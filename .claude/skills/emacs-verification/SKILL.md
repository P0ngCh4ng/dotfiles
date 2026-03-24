# Emacs Verification Skill

## Overview

Concrete commands, scripts, and procedures for verifying Emacs configuration changes.

**Dependencies**:
- Read `~/.claude/rules/emacs-environment.md` for environment detection
- Read `~/.claude/rules/verification-strategy.md` for strategy selection

## Environment Setup

### 1. Detect Emacs Executable

```bash
# Detect and set EMACS variable
detect_emacs() {
    if [ -f /Applications/Emacs.app/Contents/MacOS/Emacs ]; then
        echo "/Applications/Emacs.app/Contents/MacOS/Emacs"
    elif command -v emacs &> /dev/null; then
        echo "emacs"
    else
        echo "ERROR: Emacs not found" >&2
        return 1
    fi
}

EMACS=$(detect_emacs)
```

### 2. Verify Emacs is Available

```bash
# Test Emacs can run
test_emacs() {
    local emacs_cmd="$1"
    $emacs_cmd --version > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "✅ Emacs found: $emacs_cmd"
        return 0
    else
        echo "❌ Emacs not working: $emacs_cmd"
        return 1
    fi
}

test_emacs "$EMACS"
```

## Backup Procedures

### Create Timestamped Backup

```bash
# Backup init.el
backup_init() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="$HOME/.emacs.d/init.el.backup.$timestamp"

    cp ~/.emacs.d/init.el "$backup_file"
    echo "✅ Backup created: $backup_file"
    echo "$backup_file"
}

BACKUP_FILE=$(backup_init)
```

### Clean Old Byte-Compiled Files

```bash
# Remove .elc files to ensure testing current source
clean_byte_compiled() {
    echo "Cleaning old byte-compiled files..."

    rm -f ~/.emacs.d/init.elc
    rm -f ~/.emacs.d/elisp/*.elc

    echo "✅ Byte-compiled files cleaned"
}

clean_byte_compiled
```

## Verification Commands

### 1. Basic Syntax Check

```bash
syntax_check() {
    local emacs_cmd="$1"
    echo "=== Syntax Check ==="

    $emacs_cmd --batch -l ~/.emacs.d/init.el 2>&1 | \
        grep -v "Cannot load" | \
        tee /tmp/emacs-syntax-check.log

    # Check for actual errors
    if grep -qi "error" /tmp/emacs-syntax-check.log; then
        echo "❌ Syntax errors found"
        return 1
    else
        echo "✅ Syntax check passed"
        return 0
    fi
}

syntax_check "$EMACS"
```

### 2. Byte-Compile Verification

```bash
byte_compile_check() {
    local emacs_cmd="$1"
    local file="${2:-~/.emacs.d/init.el}"

    echo "=== Byte-Compile Check: $file ==="

    $emacs_cmd --batch --eval "(byte-compile-file \"$file\")" 2>&1 | \
        tee /tmp/emacs-byte-compile.log

    # Check for errors (ignore "Cannot load" for lazy packages)
    local errors=$(grep -i "error" /tmp/emacs-byte-compile.log | grep -v "Cannot load" | wc -l)
    local warnings=$(grep -i "warning" /tmp/emacs-byte-compile.log | wc -l)

    echo ""
    echo "Errors: $errors"
    echo "Warnings: $warnings"

    if [ $errors -gt 0 ]; then
        echo "❌ Byte-compile failed with errors"
        return 1
    elif [ $warnings -gt 0 ]; then
        echo "⚠️  Byte-compile completed with warnings"
        return 2
    else
        echo "✅ Byte-compile passed"
        return 0
    fi
}

byte_compile_check "$EMACS"
```

### 3. Runtime Test (Auto-Exit)

```bash
runtime_test() {
    local emacs_cmd="$1"
    local timeout="${2:-3}"

    echo "=== Runtime Test ($timeout second timeout) ==="

    $emacs_cmd --eval "(run-with-timer $timeout nil #'kill-emacs)" 2>&1 | \
        tee /tmp/emacs-runtime-test.log

    local exit_code=$?

    if [ $exit_code -eq 0 ]; then
        echo "✅ Runtime test passed"
        return 0
    else
        echo "❌ Runtime test failed (exit code: $exit_code)"
        return 1
    fi
}

runtime_test "$EMACS" 3
```

### 4. Package Initialization Check

```bash
package_init_check() {
    local emacs_cmd="$1"

    echo "=== Package Initialization Check ==="

    $emacs_cmd --batch --eval "(progn (require 'package) (package-initialize))" 2>&1 | \
        tee /tmp/emacs-package-init.log

    if [ $? -eq 0 ]; then
        echo "✅ Package initialization passed"
        return 0
    else
        echo "❌ Package initialization failed"
        return 1
    fi
}

package_init_check "$EMACS"
```

### 5. Messages Buffer Check

```bash
messages_check() {
    local emacs_cmd="$1"

    echo "=== Messages Buffer Check ==="

    $emacs_cmd --batch --eval "(progn \
        (load-file \"~/.emacs.d/init.el\") \
        (with-current-buffer \"*Messages*\" \
            (princ (buffer-string))))" 2>&1 | \
        tee /tmp/emacs-messages.log

    # Look for errors in messages
    if grep -qi "error" /tmp/emacs-messages.log; then
        echo "⚠️  Errors found in *Messages* buffer"
        echo "Check /tmp/emacs-messages.log for details"
        return 1
    else
        echo "✅ No errors in *Messages* buffer"
        return 0
    fi
}

messages_check "$EMACS"
```

## Comprehensive Verification Script

```bash
#!/bin/bash
# comprehensive-emacs-verify.sh

set -e

# Configuration
EMACS=""
BACKUP_FILE=""
ERRORS=0
WARNINGS=0

# Functions (include all from above)
detect_emacs() { ... }
test_emacs() { ... }
backup_init() { ... }
clean_byte_compiled() { ... }
syntax_check() { ... }
byte_compile_check() { ... }
runtime_test() { ... }
package_init_check() { ... }
messages_check() { ... }

# Main execution
main() {
    echo "========================================="
    echo "  Emacs Configuration Verification"
    echo "========================================="
    echo ""

    # 1. Detect Emacs
    EMACS=$(detect_emacs) || exit 1
    test_emacs "$EMACS" || exit 1
    echo ""

    # 2. Backup
    BACKUP_FILE=$(backup_init)
    echo ""

    # 3. Clean old files
    clean_byte_compiled
    echo ""

    # 4. Run checks
    syntax_check "$EMACS"
    ERRORS=$((ERRORS + $?))
    echo ""

    byte_compile_check "$EMACS"
    local bc_result=$?
    if [ $bc_result -eq 1 ]; then
        ERRORS=$((ERRORS + 1))
    elif [ $bc_result -eq 2 ]; then
        WARNINGS=$((WARNINGS + 1))
    fi
    echo ""

    runtime_test "$EMACS" 3
    ERRORS=$((ERRORS + $?))
    echo ""

    package_init_check "$EMACS"
    ERRORS=$((ERRORS + $?))
    echo ""

    messages_check "$EMACS"
    ERRORS=$((ERRORS + $?))
    echo ""

    # 5. Summary
    echo "========================================="
    echo "  Verification Summary"
    echo "========================================="
    echo "Errors: $ERRORS"
    echo "Warnings: $WARNINGS"
    echo "Backup: $BACKUP_FILE"
    echo ""

    if [ $ERRORS -eq 0 ]; then
        echo "✅ All batch mode checks passed"
        echo ""
        echo "⚠️  IMPORTANT: Batch mode cannot verify:"
        echo "   - Lazy-loaded packages (:after, :defer)"
        echo "   - Keybindings for lazy-loaded features"
        echo "   - Interactive commands"
        echo ""
        echo "📋 Manual test required:"
        echo "   1. Launch /Applications/Emacs.app"
        echo "   2. Check *Messages* buffer for errors"
        echo "   3. Test your specific feature (e.g., C-c C-p)"
        echo ""
        return 0
    else
        echo "❌ Verification failed with $ERRORS error(s)"
        echo ""
        echo "Check these log files for details:"
        echo "   /tmp/emacs-syntax-check.log"
        echo "   /tmp/emacs-byte-compile.log"
        echo "   /tmp/emacs-runtime-test.log"
        echo "   /tmp/emacs-package-init.log"
        echo "   /tmp/emacs-messages.log"
        echo ""
        return 1
    fi
}

main "$@"
```

## GUI Emacs Test Templates

### Function Definition Test

```elisp
;; Test if function is defined
;; Usage: M-x eval-expression (or M-:)

(if (fboundp 'FUNCTION-NAME)
    (message "✅ Function FUNCTION-NAME is defined")
  (message "❌ Function FUNCTION-NAME NOT defined"))
```

### Keybinding Test

```elisp
;; Test keybinding
;; Usage: M-x eval-expression (or M-:)

(let ((binding (key-binding (kbd "KEY-SEQUENCE"))))
  (if binding
      (message "✅ KEY-SEQUENCE is bound to: %s" binding)
    (message "❌ KEY-SEQUENCE is NOT bound")))
```

### Package Load Test

```elisp
;; Test if package is loaded
;; Usage: M-x eval-expression (or M-:)

(if (featurep 'PACKAGE-NAME)
    (message "✅ Package PACKAGE-NAME is loaded")
  (message "❌ Package PACKAGE-NAME NOT loaded"))
```

### Comprehensive Feature Test

```elisp
;; Comprehensive test for lazy-loaded feature
;; Usage: Save to file and M-x eval-buffer

(message "=== Feature Test: FEATURE-NAME ===")

;; 1. Package loaded?
(if (featurep 'PACKAGE-NAME)
    (message "✅ Package loaded")
  (message "❌ Package NOT loaded (try: M-x require RET PACKAGE-NAME)"))

;; 2. Function defined?
(if (fboundp 'FUNCTION-NAME)
    (message "✅ Function defined")
  (message "❌ Function NOT defined"))

;; 3. Keybinding registered?
(let ((binding (key-binding (kbd "KEY-SEQUENCE"))))
  (if binding
      (message "✅ Keybinding: %s" binding)
    (message "❌ Keybinding NOT registered")))

;; 4. Try to load if needed
(unless (featurep 'PACKAGE-NAME)
  (message "Attempting to load PACKAGE-NAME...")
  (require 'PACKAGE-NAME nil t)
  (if (featurep 'PACKAGE-NAME)
      (message "✅ Package loaded successfully")
    (message "❌ Package load failed")))

(message "=== Test Complete ===")
```

## Error Analysis Patterns

### Ignore These in Batch Mode

```bash
# Filter out expected "Cannot load" messages for lazy-loaded packages
grep -v "Cannot load" /tmp/emacs-check.log | \
grep -v "file-missing.*No such file or directory" | \
grep -i "error"
```

### Real Errors to Fix

```bash
# Look for actual syntax/configuration errors
grep -E "error|Error|ERROR" /tmp/emacs-check.log | \
grep -v "Cannot load" | \
grep -v "file-missing" | \
grep -v ":after" | \
grep -v ":defer"
```

### Warning Analysis

```bash
# Extract warnings that need attention
grep -i "warning" /tmp/emacs-byte-compile.log | \
grep -v "obsolete" | \
grep -v "deprecated"
```

## Quick Reference Commands

```bash
# Environment detection
EMACS=$(detect_emacs)

# Full verification
bash comprehensive-emacs-verify.sh

# Quick syntax check
$EMACS --batch -l ~/.emacs.d/init.el 2>&1 | grep -v "Cannot load"

# Quick byte-compile
$EMACS --batch --eval "(byte-compile-file \"~/.emacs.d/init.el\")"

# Clean byte-compiled files
rm -f ~/.emacs.d/init.elc ~/.emacs.d/elisp/*.elc

# Backup init.el
cp ~/.emacs.d/init.el ~/.emacs.d/init.el.backup.$(date +%Y%m%d_%H%M%S)
```

## Troubleshooting Decision Tree

```
Error found?
│
├─ "Cannot load PACKAGE"
│  ├─ Package uses :after or :defer?
│  │  └─ YES → IGNORE (normal in batch mode)
│  │
│  └─ Package should load immediately?
│     └─ YES → FIX (package missing or path wrong)
│
├─ "Unbalanced parentheses" / "Invalid read syntax"
│  └─ FIX syntax error in init.el
│
├─ "Undefined function WARNING"
│  ├─ Function from lazy-loaded package?
│  │  └─ YES → IGNORE or add (declare-function ...)
│  │
│  └─ Function should exist?
│     └─ YES → FIX (add require or fix function name)
│
└─ "Cannot open load file"
   ├─ File uses :after or :defer?
   │  └─ YES → IGNORE (will load in GUI)
   │
   └─ File should load immediately?
      └─ YES → FIX (file missing or path wrong)
```

## Best Practices Checklist

- [ ] Always backup before modifying init.el
- [ ] Clean .elc files before verification
- [ ] Run all 5 verification commands
- [ ] Understand batch mode limitations
- [ ] Filter out expected "Cannot load" messages
- [ ] Create GUI test plan for lazy-loaded features
- [ ] Document manual test steps clearly
- [ ] Provide elisp test snippets for semi-automation
- [ ] Don't assume batch mode failure = actual failure
- [ ] Always test critical features in GUI Emacs
