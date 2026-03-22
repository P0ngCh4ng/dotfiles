# Verify Emacs Configuration

Perform comprehensive verification of Emacs configuration files with environment-aware testing.

**IMPORTANT**: Before running this command, read:
- `~/.claude/rules/emacs-environment.md` - Environment detection and batch mode limitations
- `~/.claude/rules/verification-strategy.md` - When to use which verification method
- `~/.claude/skills/emacs-verification/SKILL.md` - Concrete verification commands

## Quick Reference

**What this command does**:
1. Detects Emacs environment (GUI vs CLI)
2. Runs batch mode syntax/compilation checks
3. **Cannot verify lazy-loaded features** (`:after`, `:defer`)
4. Provides GUI test instructions for features that need manual verification

**What you MUST test in GUI Emacs yourself**:
- Keybindings for packages with `:after` directive
- Interactive commands from lazy-loaded packages
- Features that depend on vterm, claude-code, or GUI-only packages

## Step 1: Detect Emacs Environment

```bash
# Auto-detect Emacs executable
if [ -f /Applications/Emacs.app/Contents/MacOS/Emacs ]; then
    EMACS="/Applications/Emacs.app/Contents/MacOS/Emacs"
elif command -v emacs &> /dev/null; then
    EMACS="emacs"
else
    echo "ERROR: Emacs not found"
    echo "Expected location: /Applications/Emacs.app/Contents/MacOS/Emacs"
    exit 1
fi

echo "Using Emacs: $EMACS"
```

## Step 2: Create Backup

```bash
BACKUP_FILE="$HOME/.emacs.d/init.el.backup.$(date +%Y%m%d_%H%M%S)"
cp ~/.emacs.d/init.el "$BACKUP_FILE"
echo "✅ Backup created: $BACKUP_FILE"
```

## Step 3: Clean Old Byte-Compiled Files

```bash
echo "Cleaning stale byte-compiled files..."
rm -f ~/.emacs.d/init.elc ~/.emacs.d/elisp/*.elc
echo "✅ Byte-compiled files removed"
```

**Why**: Even with `load-prefer-newer t`, removing `.elc` files ensures you're testing current source code.

## Step 4: Run Batch Mode Verification

**CRITICAL**: Batch mode verification has limitations (see `~/.claude/rules/emacs-environment.md`).

### 4.1 Basic Syntax Check

```bash
echo "=== Syntax Check ==="
$EMACS --batch -l ~/.emacs.d/init.el 2>&1 | grep -v "Cannot load" | tee /tmp/emacs-syntax.log
```

**Ignore**: "Cannot load" messages for packages with `:after` or `:defer` (normal behavior).

### 4.2 Byte-Compile Validation

```bash
echo "=== Byte-Compile Check ==="
$EMACS --batch --eval "(byte-compile-file \"~/.emacs.d/init.el\")" 2>&1 | tee /tmp/emacs-compile.log
```

### 4.3 Runtime Test (Auto-Exit)

```bash
echo "=== Runtime Test (3-second timeout) ==="
$EMACS --eval "(run-with-timer 3 nil #'kill-emacs)" 2>&1 | tee /tmp/emacs-runtime.log
```

### 4.4 Package Initialization

```bash
echo "=== Package Initialization ==="
$EMACS --batch --eval "(progn (require 'package) (package-initialize))" 2>&1 | tee /tmp/emacs-package.log
```

### 4.5 Messages Buffer Check

```bash
echo "=== Messages Buffer Check ==="
$EMACS --batch --eval "(progn (load-file \"~/.emacs.d/init.el\") (with-current-buffer \"*Messages*\" (princ (buffer-string))))" 2>&1 | tee /tmp/emacs-messages.log
```

## Step 5: Analyze Results

### Categorize Issues

```bash
# Count actual errors (ignore lazy-load "Cannot load")
ERRORS=$(cat /tmp/emacs-*.log | grep -i "error" | grep -v "Cannot load" | grep -v "file-missing.*:after" | wc -l)

# Count warnings
WARNINGS=$(grep -i "warning" /tmp/emacs-compile.log | wc -l)

echo ""
echo "========================================="
echo "  Batch Mode Verification Results"
echo "========================================="
echo "Errors: $ERRORS"
echo "Warnings: $WARNINGS"
echo ""
```

### Filter Expected Messages

**Expected in batch mode** (not errors):
- `Cannot load claude-code` - Uses `:after vterm`
- `Cannot load claude-code-projects` - Uses `:after claude-code`
- `Cannot load vterm` - GUI-dependent package
- Any package with `:after` or `:defer` directive

**Real errors to fix**:
- Syntax errors (unbalanced parentheses, quotes)
- Undefined functions (not from lazy-loaded packages)
- Missing files (not lazy-loaded)
- Byte-compilation errors

## Step 6: Report Findings

Create a comprehensive report showing:

1. **Batch mode results** (syntax, compilation)
2. **Limitations** (what couldn't be tested)
3. **Manual test instructions** (GUI Emacs required)
4. **Error details** (if any found)

## Step 7: Auto-Fix Common Issues

**Only fix real errors**, not expected lazy-load messages:

```bash
# Example auto-fixes
# - Missing packages → Add (package-install 'package-name)
# - Syntax errors → Fix quotes, parentheses
# - Undefined functions → Add (require 'feature) or (declare-function ...)
# - Obsolete functions → Replace with modern equivalents
```

**DO NOT try to fix**:
- "Cannot load" for packages with `:after` (working as designed)
- Missing keybindings in batch mode (can't be tested in batch)
- Interactive command unavailability (batch mode limitation)

## Step 8: Create GUI Test Plan

For features that **cannot be verified in batch mode**, provide clear manual test instructions:

```markdown
## Manual Testing Required in GUI Emacs

**Why**: The following features use `:after` or `:defer` and won't load in batch mode.

### Test: C-c C-p keybinding (claude-code-projects)

**Dependencies**: vterm → claude-code → claude-code-projects (chain loading)

**Steps**:
1. Launch GUI Emacs: `open /Applications/Emacs.app`
2. Wait for initialization (~5-10 seconds)
3. Check *Messages* buffer: `C-x b *Messages* RET`
   - Look for errors (scroll to bottom)
4. Test function exists: `M-:` (eval-expression)
   ```elisp
   (fboundp 'claude-code-select-project)
   ```
   - Should return `t`
5. Test keybinding: `M-:`
   ```elisp
   (key-binding (kbd "C-c C-p"))
   ```
   - Should return `claude-code-select-project`
6. **Actually press C-c C-p**
   - Should show project selection prompt
7. Select a project and verify it starts Claude Code

**If it doesn't work**:
- Check if vterm loaded: `M-: (featurep 'vterm)`
- Check if claude-code loaded: `M-: (featurep 'claude-code)`
- Check if claude-code-projects loaded: `M-: (featurep 'claude-code-projects)`
- Try manual load: `M-x require RET claude-code RET`
```

## Step 9: Success Criteria

### Batch Mode (Automated)

✅ Syntax check passes (no errors)
✅ Byte-compilation succeeds (no errors, ideally no warnings)
✅ Runtime test completes (Emacs starts and exits)
✅ Package initialization works
✅ No errors in *Messages* buffer (except expected lazy-load messages)

### GUI Mode (Manual)

✅ All lazy-loaded packages load correctly
✅ Keybindings work as expected
✅ Interactive commands are available
✅ No errors in *Messages* buffer after full initialization
✅ Specific features (like C-c C-p) work correctly

## Step 10: Final Report

```markdown
# Emacs Verification Report

## Environment
- Emacs: [path]
- Version: [version]
- Backup: [backup file path]

## Batch Mode Results
- ✅ Syntax: PASS
- ✅ Byte-compile: PASS (0 errors, X warnings)
- ✅ Runtime: PASS
- ✅ Packages: PASS

## Batch Mode Limitations
⚠️ The following could NOT be verified in batch mode:
- Lazy-loaded packages (`:after`, `:defer`)
- Keybindings for lazy-loaded features
- Interactive commands from deferred packages
- GUI-specific features

## Required Manual Tests
📋 Test these in GUI Emacs (/Applications/Emacs.app):
1. [Feature 1]: [Test steps]
2. [Feature 2]: [Test steps]
...

## Issues Found
- [List of actual errors, if any]

## Next Steps
- [ ] If errors found: Fix and re-run verification
- [ ] Launch GUI Emacs and perform manual tests
- [ ] Verify all features work as expected
```

## Usage

```bash
# Run this verification
/verify-emacs [optional: describe what you changed]

# For autonomous verification with auto-fixing
/emacs-verifier
```

## Important Notes

1. **Batch mode is NOT sufficient** for complete verification
2. **Always test critical features** in GUI Emacs after batch verification passes
3. **"Cannot load" messages** for lazy-loaded packages are **expected and normal**
4. **Don't try to "fix"** lazy-loading behavior - it's working as designed
5. **Provide clear manual test instructions** instead of claiming batch mode coverage

## Related Documentation

- Environment rules: `~/.claude/rules/emacs-environment.md`
- Verification strategy: `~/.claude/rules/verification-strategy.md`
- Concrete commands: `~/.claude/skills/emacs-verification/SKILL.md`
