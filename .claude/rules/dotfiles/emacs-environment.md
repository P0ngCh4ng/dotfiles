# Emacs Environment Rules

## Environment Detection

### Primary Emacs Launch Method
- **GUI Application**: `/Applications/Emacs.app` (macOS GUI version)
- **NOT used**: Terminal `emacs -nw` or command-line launch
- **Configuration optimized for**: GUI Emacs with graphical features

### Emacs Executable Paths

```bash
# GUI Emacs executable
/Applications/Emacs.app/Contents/MacOS/Emacs

# Emacs may NOT be in PATH
# Always check before using 'emacs' command
which emacs || echo "emacs not in PATH"
```

### Environment Detection Commands

```bash
# 1. Check if Emacs.app exists
ls /Applications/Emacs.app/Contents/MacOS/Emacs

# 2. Check if emacs is in PATH
which emacs

# 3. Determine correct executable
if [ -f /Applications/Emacs.app/Contents/MacOS/Emacs ]; then
    EMACS_CMD="/Applications/Emacs.app/Contents/MacOS/Emacs"
elif command -v emacs &> /dev/null; then
    EMACS_CMD="emacs"
else
    echo "ERROR: Emacs not found"
    exit 1
fi
```

## Batch Mode Limitations

### Critical Understanding

**Batch mode (`emacs --batch`) has fundamental limitations that prevent complete verification:**

1. **`:after` directives don't trigger**
   - `use-package` with `:after vterm` won't load in batch mode
   - `use-package` with `:after claude-code` won't load in batch mode
   - Chain loading doesn't occur: vterm → claude-code → claude-code-projects

2. **Package initialization differs**
   - Some packages require GUI context
   - Interactive features are unavailable
   - Display-related configurations fail silently

3. **What batch mode CAN verify**
   - ✅ Syntax errors
   - ✅ File loading errors
   - ✅ Basic require/load statements
   - ✅ Byte-compilation issues

4. **What batch mode CANNOT verify**
   - ❌ Lazy-loaded packages (`:after`, `:defer`)
   - ❌ Keybindings for lazy-loaded packages
   - ❌ Interactive commands availability
   - ❌ GUI-specific configurations

### When to Use Each Mode

| Verification Type | Use Batch Mode | Use GUI Emacs |
|-------------------|----------------|---------------|
| Syntax check | ✅ | ✅ |
| Byte-compile | ✅ | ✅ |
| Package loading | ❌ | ✅ |
| Keybinding test | ❌ | ✅ |
| Interactive commands | ❌ | ✅ |
| Full functionality | ❌ | ✅ |

## Verification Strategy by Context

### For Syntax/Compilation Issues
**Use batch mode**: Fast, automated, suitable for CI/CD

```bash
/Applications/Emacs.app/Contents/MacOS/Emacs --batch -l ~/.emacs.d/init.el
```

### For Package Loading Issues
**Use GUI Emacs**: Required for `:after` directives

```bash
# Launch GUI Emacs and check *Messages* buffer
open /Applications/Emacs.app
# Then in Emacs: C-x b *Messages* RET
```

### For Keybinding Issues (like C-c C-p)
**MUST use GUI Emacs**: Batch mode cannot verify lazy-loaded keybindings

```elisp
;; In running GUI Emacs, evaluate:
(key-binding (kbd "C-c C-p"))
```

## Critical Rule for Verification

**NEVER attempt to verify lazy-loaded features in batch mode.**

If you encounter:
- `use-package ... :after PACKAGE`
- `use-package ... :defer t`
- Keybindings defined in lazy-loaded packages

Then:
1. ✅ Verify syntax in batch mode
2. ✅ Verify byte-compilation in batch mode
3. ❌ DO NOT expect the package to load in batch mode
4. ✅ Create GUI Emacs test instructions for the user

## Error Handling

### Expected "Cannot load" Messages in Batch Mode

When using batch mode with lazy-loaded packages, messages like this are **NORMAL**:

```
Cannot load claude-code: (file-missing "Cannot open load file" ...)
```

**This is NOT an error** if the package is configured with `:after` or `:defer`.

### Actual Errors to Fix

Only fix these in batch mode:
- Syntax errors (unbalanced parentheses, quotes)
- Missing files referenced without lazy loading
- Byte-compilation warnings about undefined functions (when not lazy-loaded)
- Hard-coded paths that don't exist

## Best Practices

1. **Always detect environment first** before running verification
2. **Choose appropriate verification method** based on what you're testing
3. **Don't over-rely on batch mode** for complex configurations
4. **Provide GUI test instructions** when batch mode is insufficient
5. **Document limitations clearly** when batch verification fails

## Example: Correct Verification Workflow

```bash
#!/bin/bash

# 1. Detect Emacs
if [ -f /Applications/Emacs.app/Contents/MacOS/Emacs ]; then
    EMACS="/Applications/Emacs.app/Contents/MacOS/Emacs"
else
    EMACS="emacs"
fi

# 2. Backup
cp ~/.emacs.d/init.el ~/.emacs.d/init.el.backup.$(date +%Y%m%d_%H%M%S)

# 3. Syntax check (batch mode)
echo "Running syntax check..."
$EMACS --batch -l ~/.emacs.d/init.el 2>&1 | grep -v "Cannot load"

# 4. Byte-compile (batch mode)
echo "Running byte-compile..."
$EMACS --batch --eval "(byte-compile-file \"~/.emacs.d/init.el\")" 2>&1

# 5. Report limitations
echo ""
echo "✅ Syntax and byte-compilation verified"
echo "⚠️  Package loading and keybindings MUST be tested in GUI Emacs"
echo "   Please launch /Applications/Emacs.app and test manually"
```
