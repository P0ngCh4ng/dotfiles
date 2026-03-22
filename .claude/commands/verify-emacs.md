# Verify Emacs Configuration

Perform comprehensive verification of Emacs configuration files to ensure they are error-free and warning-free.

## Verification Workflow

Execute the following steps in order:

### 1. Create Backup
```bash
cp ~/.emacs.d/init.el ~/.emacs.d/init.el.backup.$(date +%Y%m%d_%H%M%S)
```

### 2. Clean Old Byte-Compiled Files

**Automatically detect and remove stale .elc files:**

```bash
# Find all .el files that are newer than their .elc counterparts
for el in ~/.emacs.d/init.el ~/.emacs.d/elisp/*.el; do
  elc="${el}c"
  if [ -f "$elc" ] && [ "$el" -nt "$elc" ]; then
    echo "Removing stale: $elc (source is newer)"
    rm -f "$elc"
  fi
done
```

**Or simply remove all .elc files to be safe:**
```bash
rm -f ~/.emacs.d/init.elc ~/.emacs.d/elisp/*.elc
```

**CRITICAL**: Even with `load-prefer-newer t`, it's best practice to remove stale `.elc` files during development to avoid confusion.

### 3. Run ALL Verification Commands

Execute each command and capture BOTH stderr and stdout:

#### Basic Syntax Check
```bash
emacs --batch -l ~/.emacs.d/init.el 2>&1
```

#### Runtime Test (3-second auto-exit)
```bash
emacs --eval "(run-with-timer 3 nil #'kill-emacs)" 2>&1
```

#### Byte-Compile Validation
```bash
emacs --batch --eval "(byte-compile-file \"~/.emacs.d/init.el\")" 2>&1
```

#### Package Verification
```bash
emacs --batch --eval "(progn (require 'package) (package-initialize))" 2>&1
```

#### Messages Buffer Check
```bash
emacs --batch --eval "(progn (load-file \"~/.emacs.d/init.el\") (with-current-buffer \"*Messages*\" (princ (buffer-string))))" 2>&1
```

### 4. Analyze Results

Parse ALL output for:
- **Errors**: Syntax errors, runtime errors, loading errors
- **Warnings**: Obsolete functions, deprecated variables, undefined functions
- **Compilation warnings**: Unused variables, wrong argument counts
- **Package issues**: Missing packages, version conflicts

### 5. Report Findings

Create a comprehensive report including:
- Total count of errors and warnings
- Categorized list of issues
- Severity assessment (Critical/High/Medium/Low)
- Specific file and line numbers when available

### 6. Auto-Fix Issues

Automatically fix common issues:
- Missing packages → `(package-install 'package-name)`
- Syntax errors → Correct quotes, parentheses
- Undefined functions → Add `(require 'feature)`
- Obsolete functions → Replace with modern equivalents
- Deprecated variables → Update to new names
- Wrong number of arguments → Fix function calls
- Unbalanced parentheses → Balance properly

### 7. Re-Verify After Fixes

Re-run ALL verification commands after making fixes.

### 8. Iterate Until Clean

**CRITICAL**: Continue the fix-verify cycle until:
- ZERO errors
- ZERO warnings
- Emacs starts successfully without any messages

## Success Criteria

✅ All 5 verification commands complete without errors
✅ No warnings in any output
✅ Emacs launches and exits cleanly
✅ No messages in *Messages* buffer indicating issues
✅ Byte-compilation succeeds without warnings
✅ Stale .elc files removed

## After Verification (Optional)

If this is a **completed, stable feature** and you want performance benefits:
```bash
# Byte-compile the file
emacs --batch --eval "(byte-compile-file \"~/.emacs.d/elisp/YOUR-FILE.el\")"
```

**Don't byte-compile during active development** - `load-prefer-newer t` will use the newer `.el` file, but it's cleaner to just delete `.elc` files while developing.

## Failure Conditions

❌ Any error messages in verification output
❌ Any warning messages in verification output
❌ Emacs fails to start
❌ Byte-compilation produces warnings
❌ Package initialization fails

## Feature-Specific Verification

When adding new commands, keybindings, or modes, verify they work correctly:

### When Adding Interactive Commands
1. Verify command is interactive:
```bash
emacs --batch --eval "(progn (load-file \"~/.emacs.d/init.el\") (princ (if (commandp 'COMMAND-NAME) \"✓ Interactive\" \"✗ Not interactive\")))" 2>&1
```
2. Verify autoload configured:
```bash
emacs --batch --eval "(progn (load-file \"~/.emacs.d/init.el\") (princ (if (autoloadp (symbol-function 'COMMAND-NAME)) \"✓ Autoload\" \"✗ No autoload\")))" 2>&1
```
3. **Test in helm-M-x**: Launch Emacs and check if command appears in `helm-M-x` or `M-x`
4. **Execute the command**: Run it and verify expected behavior

### When Adding Keybindings
1. Verify binding registered:
```bash
emacs --batch --eval "(progn (load-file \"~/.emacs.d/init.el\") (princ (key-binding (kbd \"KEY-SEQUENCE\"))))" 2>&1
```
2. **Test the key**: Press the key combination and verify it invokes the correct command
3. Check for conflicts: Verify the key isn't already bound to something important

### When Adding New Modes
1. Verify mode function exists:
```bash
emacs --batch --eval "(progn (load-file \"~/.emacs.d/init.el\") (princ (if (fboundp 'MODE-NAME) \"✓ Mode defined\" \"✗ Not defined\")))" 2>&1
```
2. **Test mode activation**: Enable the mode and verify it works
3. **Test mode keybindings**: Press each key defined in the mode keymap and verify functionality
4. **Test mode hooks**: Verify hooks execute as expected
5. Verify mode-specific faces/variables are applied correctly

## Usage

After editing any Emacs configuration file, run:
```
/verify-emacs
```

Or invoke the emacs-verifier agent for autonomous verification:
```
/emacs-verifier
```
