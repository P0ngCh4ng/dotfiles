# Emacs Verification Strategy Rules

## Decision Tree: Choosing Verification Method

```
START: What are you verifying?
│
├─ Syntax errors / Compilation issues?
│  └─ YES → Use batch mode
│     ├─ emacs --batch -l init.el
│     └─ emacs --batch --eval "(byte-compile-file ...)"
│
├─ Package installation / loading?
│  ├─ Package has :after or :defer?
│  │  ├─ YES → MUST use GUI Emacs (batch mode will fail)
│  │  └─ NO → Can use batch mode
│  │
│  └─ Involves vterm, claude-code, or GUI packages?
│     └─ YES → MUST use GUI Emacs
│
├─ Keybindings?
│  ├─ Defined in lazy-loaded package?
│  │  └─ YES → MUST use GUI Emacs + manual test
│  │
│  └─ Global keybindings?
│     └─ Can verify in batch, but test in GUI recommended
│
└─ Interactive commands / workflows?
   └─ MUST use GUI Emacs
```

## Strategy by Change Type

### 1. Adding New Package

**When**: Adding `use-package` declaration

**Strategy**:
- ✅ Syntax check in batch mode
- ✅ Byte-compile in batch mode
- ⚠️ If package has `:after` → Create GUI test plan
- ✅ Install test in GUI Emacs

**Commands**:
```bash
# Batch verification (syntax only)
$EMACS --batch -l ~/.emacs.d/init.el 2>&1 | grep -E "error|Error"

# GUI test instructions
echo "Test in GUI Emacs:"
echo "1. Launch /Applications/Emacs.app"
echo "2. Check *Messages* buffer for errors"
echo "3. M-x list-packages to verify installation"
```

### 2. Modifying Keybindings

**When**: Changing key mappings, especially for lazy-loaded packages

**Strategy**:
- ❌ DO NOT rely on batch mode
- ✅ Create test elisp snippet
- ✅ Provide manual test instructions
- ✅ Include fallback binding if needed

**Test Template**:
```elisp
;; Test in running GUI Emacs (M-x eval-expression):

;; 1. Check if function exists
(fboundp 'FUNCTION-NAME)  ; Should return t

;; 2. Check keybinding
(key-binding (kbd "KEY-SEQUENCE"))  ; Should return FUNCTION-NAME

;; 3. Actually test the key
;; Press the key combination and verify behavior
```

### 3. Fixing Configuration Errors

**When**: init.el won't load or has errors

**Strategy**:
1. **Backup first** (always)
2. **Syntax check** in batch mode
3. **Identify error type**:
   - Syntax → Fix and recheck in batch
   - Package loading → Check in GUI
   - Lazy loading → GUI test only
4. **Iterative fixing** with appropriate verification

**Workflow**:
```bash
# 1. Backup
cp ~/.emacs.d/init.el ~/.emacs.d/init.el.backup.$(date +%Y%m%d_%H%M%S)

# 2. Syntax check
$EMACS --batch -l ~/.emacs.d/init.el 2>&1 > /tmp/emacs-syntax-check.log

# 3. Analyze errors
grep -i "error" /tmp/emacs-syntax-check.log
# Ignore "Cannot load" for lazy-loaded packages

# 4. Fix identified issues

# 5. Re-verify syntax

# 6. Create GUI test instructions for lazy-loaded features
```

### 4. Adding Custom elisp Files

**When**: Adding files to `~/.emacs.d/elisp/`

**Strategy**:
- ✅ Test file in isolation first
- ✅ Byte-compile individually
- ✅ Test loading in batch mode
- ✅ If depends on other packages, test in GUI

**Test Commands**:
```bash
# 1. Test loading in isolation
$EMACS --batch --eval "(progn (add-to-list 'load-path \"~/.emacs.d/elisp\") (load \"FILE-NAME\"))"

# 2. Byte-compile
$EMACS --batch --eval "(byte-compile-file \"~/.emacs.d/elisp/FILE-NAME.el\")"

# 3. Check for undefined functions
$EMACS --batch --eval "(byte-compile-file \"~/.emacs.d/elisp/FILE-NAME.el\")" 2>&1 | grep -i "undefined"
```

## Limitation Awareness Matrix

| Feature | Batch Mode | GUI Emacs | Manual Test Required |
|---------|------------|-----------|---------------------|
| Syntax errors | ✅ Detects | ✅ Detects | ❌ |
| Byte-compile | ✅ Works | ✅ Works | ❌ |
| Package install | ❌ Limited | ✅ Full | ❌ |
| `:after` packages | ❌ Won't load | ✅ Loads | ❌ |
| `:defer` packages | ❌ Won't load | ✅ Loads | ❌ |
| Keybindings | ⚠️ Partial | ✅ Full | ✅ Recommended |
| Interactive commands | ❌ Can't test | ✅ Can test | ✅ Required |
| GUI features | ❌ Unavailable | ✅ Available | ✅ Required |
| vterm | ❌ Won't work | ✅ Works | ❌ |
| claude-code | ❌ Won't load (`:after vterm`) | ✅ Loads | ✅ Required |

## Common Pitfalls to Avoid

### ❌ WRONG: Using batch mode for everything

```bash
# This will FAIL to verify lazy-loaded features
emacs --batch -l ~/.emacs.d/init.el
# Then assuming everything is broken because packages didn't load
```

**Why wrong**: Lazy-loaded packages won't load in batch mode, causing false negatives.

### ✅ RIGHT: Use batch for syntax, GUI for functionality

```bash
# 1. Verify syntax in batch
emacs --batch -l ~/.emacs.d/init.el 2>&1 | grep -v "Cannot load"

# 2. Then provide GUI test instructions
cat <<EOF
Syntax verified. Now test functionality in GUI Emacs:
1. Launch /Applications/Emacs.app
2. Try the feature (e.g., C-c C-p)
3. Check *Messages* buffer for errors
EOF
```

### ❌ WRONG: Expecting keybindings to work in batch mode

```bash
# This CANNOT work
emacs --batch --eval "(key-binding (kbd \"C-c C-p\"))"
```

**Why wrong**: Keybindings for lazy-loaded packages aren't registered until the package loads, which doesn't happen in batch mode with `:after`.

### ✅ RIGHT: Create elisp test snippet for GUI Emacs

```elisp
;; Save this and run in GUI Emacs with M-x eval-buffer

(message "=== Keybinding Test ===")

;; Check function
(if (fboundp 'claude-code-select-project)
    (message "✅ Function defined")
  (message "❌ Function NOT defined"))

;; Check binding
(let ((binding (key-binding (kbd "C-c C-p"))))
  (if binding
      (message "✅ C-c C-p bound to: %s" binding)
    (message "❌ C-c C-p NOT bound")))
```

## Automation Strategy

### What to Automate

✅ **Automate these in batch mode**:
- Syntax checking
- Byte-compilation
- Basic file loading
- Backup creation

❌ **DO NOT automate in batch mode**:
- Lazy-loaded package verification
- Keybinding tests for `:after` packages
- Interactive command testing
- Full functionality validation

### What to Provide as Manual Test Instructions

For features that can't be verified in batch mode:

1. **Clear, step-by-step instructions**
2. **Expected outcomes** for each step
3. **Elisp snippets** for semi-automated checking
4. **Troubleshooting steps** if tests fail

**Template**:
```markdown
## Manual Test Required

**Feature**: [Description]
**Why manual**: [Lazy loading / GUI required / etc]

### Test Steps

1. Launch GUI Emacs: `/Applications/Emacs.app`
2. Wait for initialization (watch *Messages* buffer)
3. Test feature: [specific steps]
4. Verify outcome: [expected result]

### Semi-Automated Check

```elisp
;; Run with M-x eval-expression
(and (fboundp 'FUNCTION-NAME)
     (key-binding (kbd "KEY"))
     (message "✅ Test passed"))
```

### Troubleshooting

If test fails:
- Check *Messages* buffer: `C-x b *Messages*`
- Verify package loaded: `M-x list-packages`
- Try loading manually: `M-x require RET PACKAGE-NAME`
```

## Final Rule

**When in doubt, prefer GUI Emacs testing over batch mode automation.**

It's better to provide accurate manual test instructions than to create automated tests that give false results.
