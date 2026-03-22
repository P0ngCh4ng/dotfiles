# Emacs Configuration Verification

Manually verify Emacs configuration files with comprehensive checks.

## What This Does

Runs all 5 verification checks on your Emacs configuration:

1. **Syntax Check** - Validates elisp syntax via batch mode
2. **Runtime Test** - Actually launches Emacs to catch runtime errors
3. **Messages Buffer** - Captures all warnings from `*Messages*`
4. **Byte Compile** - Checks for compilation warnings and errors
5. **Package Verification** - Validates package system initialization

## Usage

```bash
/verify-emacs
```

This command will:
- Run all 5 checks on `~/.emacs.d/init.el`
- Parse and categorize errors vs warnings
- Report findings in readable markdown format
- **NOT** automatically fix issues (read-only verification)

## When to Use

- After manually editing `init.el` or elisp files
- Before committing Emacs configuration changes
- To verify that your config is clean
- When you want detailed diagnostics without auto-fix

## Output Format

```
╔═══════════════════════════════════════╗
║  Emacs Configuration Verification    ║
╚═══════════════════════════════════════╝

File: /Users/you/.emacs.d/init.el

1. Syntax Check ..................... ✓ PASSED
2. Runtime Test ..................... ✓ PASSED
3. Messages Buffer Check ............ ✗ FAILED (2 warnings)
4. Byte Compile ..................... ✓ PASSED
5. Package Verification ............. ✓ PASSED

═══════════════════════════════════════
Summary: 0 errors, 2 warnings
═══════════════════════════════════════

Warnings:
  - Warning: assignment to free variable 'some-var'
  - Warning: 'flet' is an obsolete function (use 'cl-flet')
```

## Related Commands

- **Automatic Fix**: Edit your Emacs files and the `post-edit-emacs-verify` hook will run automatically with auto-fix
- **Agent**: Use the `emacs-verifier` agent for fully autonomous fixing

## Implementation

Run the following verification commands:

```bash
#!/usr/bin/env bash

INIT_FILE="$HOME/.emacs.d/init.el"

echo "╔═══════════════════════════════════════╗"
echo "║  Emacs Configuration Verification    ║"
echo "╚═══════════════════════════════════════╝"
echo ""
echo "File: $INIT_FILE"
echo ""

# Track totals
TOTAL_ERRORS=0
TOTAL_WARNINGS=0
ALL_ERRORS=()
ALL_WARNINGS=()

# 1. Syntax Check
echo -n "1. Syntax Check ..................... "
OUTPUT=$(emacs --batch -l "$INIT_FILE" 2>&1 || true)
ERRORS=$(echo "$OUTPUT" | grep -i "error:" | grep -v "0 errors" || true)
WARNINGS=$(echo "$OUTPUT" | grep -i "warning:" | grep -v "0 warnings" || true)

if [ -z "$ERRORS" ]; then
  echo "✓ PASSED"
else
  ERROR_COUNT=$(echo "$ERRORS" | wc -l | tr -d ' ')
  echo "✗ FAILED ($ERROR_COUNT errors)"
  TOTAL_ERRORS=$((TOTAL_ERRORS + ERROR_COUNT))
  while IFS= read -r line; do
    ALL_ERRORS+=("$line")
  done <<< "$ERRORS"
fi

if [ -n "$WARNINGS" ]; then
  WARNING_COUNT=$(echo "$WARNINGS" | wc -l | tr -d ' ')
  TOTAL_WARNINGS=$((TOTAL_WARNINGS + WARNING_COUNT))
  while IFS= read -r line; do
    ALL_WARNINGS+=("$line")
  done <<< "$WARNINGS"
fi

# 2. Runtime Test
echo -n "2. Runtime Test ..................... "
OUTPUT=$(emacs --eval "(run-with-timer 3 nil #'kill-emacs)" 2>&1 || true)
ERRORS=$(echo "$OUTPUT" | grep -i "error:" | grep -v "0 errors" || true)
WARNINGS=$(echo "$OUTPUT" | grep -i "warning:" | grep -v "0 warnings" || true)

if [ -z "$ERRORS" ]; then
  echo "✓ PASSED"
else
  ERROR_COUNT=$(echo "$ERRORS" | wc -l | tr -d ' ')
  echo "✗ FAILED ($ERROR_COUNT errors)"
  TOTAL_ERRORS=$((TOTAL_ERRORS + ERROR_COUNT))
  while IFS= read -r line; do
    ALL_ERRORS+=("$line")
  done <<< "$ERRORS"
fi

if [ -n "$WARNINGS" ]; then
  WARNING_COUNT=$(echo "$WARNINGS" | wc -l | tr -d ' ')
  TOTAL_WARNINGS=$((TOTAL_WARNINGS + WARNING_COUNT))
  while IFS= read -r line; do
    ALL_WARNINGS+=("$line")
  done <<< "$WARNINGS"
fi

# 3. Messages Buffer Check
echo -n "3. Messages Buffer Check ............ "
OUTPUT=$(emacs --batch --eval "(progn (load-file \"$INIT_FILE\") (with-current-buffer \"*Messages*\" (princ (buffer-string))))" 2>&1 || true)
ERRORS=$(echo "$OUTPUT" | grep -i "error:" | grep -v "0 errors" || true)
WARNINGS=$(echo "$OUTPUT" | grep -i "warning:" | grep -v "0 warnings" || true)

if [ -z "$ERRORS" ]; then
  echo "✓ PASSED"
else
  ERROR_COUNT=$(echo "$ERRORS" | wc -l | tr -d ' ')
  echo "✗ FAILED ($ERROR_COUNT errors)"
  TOTAL_ERRORS=$((TOTAL_ERRORS + ERROR_COUNT))
  while IFS= read -r line; do
    ALL_ERRORS+=("$line")
  done <<< "$ERRORS"
fi

if [ -n "$WARNINGS" ]; then
  WARNING_COUNT=$(echo "$WARNINGS" | wc -l | tr -d ' ')
  TOTAL_WARNINGS=$((TOTAL_WARNINGS + WARNING_COUNT))
  while IFS= read -r line; do
    ALL_WARNINGS+=("$line")
  done <<< "$WARNINGS"
fi

# 4. Byte Compile
echo -n "4. Byte Compile ..................... "
OUTPUT=$(emacs --batch --eval "(byte-compile-file \"$INIT_FILE\")" 2>&1 || true)
ERRORS=$(echo "$OUTPUT" | grep -i "error:" | grep -v "0 errors" || true)
WARNINGS=$(echo "$OUTPUT" | grep -i "warning:" | grep -v "0 warnings" || true)

if [ -z "$ERRORS" ]; then
  echo "✓ PASSED"
else
  ERROR_COUNT=$(echo "$ERRORS" | wc -l | tr -d ' ')
  echo "✗ FAILED ($ERROR_COUNT errors)"
  TOTAL_ERRORS=$((TOTAL_ERRORS + ERROR_COUNT))
  while IFS= read -r line; do
    ALL_ERRORS+=("$line")
  done <<< "$ERRORS"
fi

if [ -n "$WARNINGS" ]; then
  WARNING_COUNT=$(echo "$WARNINGS" | wc -l | tr -d ' ')
  TOTAL_WARNINGS=$((TOTAL_WARNINGS + WARNING_COUNT))
  while IFS= read -r line; do
    ALL_WARNINGS+=("$line")
  done <<< "$WARNINGS"
fi

# 5. Package Verification
echo -n "5. Package Verification ............. "
OUTPUT=$(emacs --batch --eval "(progn (require 'package) (package-initialize))" 2>&1 || true)
ERRORS=$(echo "$OUTPUT" | grep -i "error:" | grep -v "0 errors" || true)
WARNINGS=$(echo "$OUTPUT" | grep -i "warning:" | grep -v "0 warnings" || true)

if [ -z "$ERRORS" ]; then
  echo "✓ PASSED"
else
  ERROR_COUNT=$(echo "$ERRORS" | wc -l | tr -d ' ')
  echo "✗ FAILED ($ERROR_COUNT errors)"
  TOTAL_ERRORS=$((TOTAL_ERRORS + ERROR_COUNT))
  while IFS= read -r line; do
    ALL_ERRORS+=("$line")
  done <<< "$ERRORS"
fi

if [ -n "$WARNINGS" ]; then
  WARNING_COUNT=$(echo "$WARNINGS" | wc -l | tr -d ' ')
  TOTAL_WARNINGS=$((TOTAL_WARNINGS + WARNING_COUNT))
  while IFS= read -r line; do
    ALL_WARNINGS+=("$line")
  done <<< "$WARNINGS"
fi

# Summary
echo ""
echo "═══════════════════════════════════════"
if [ "$TOTAL_ERRORS" -eq 0 ] && [ "$TOTAL_WARNINGS" -eq 0 ]; then
  echo "✅ All checks passed! Configuration is clean."
else
  echo "Summary: $TOTAL_ERRORS errors, $TOTAL_WARNINGS warnings"
fi
echo "═══════════════════════════════════════"

# Show errors
if [ "$TOTAL_ERRORS" -gt 0 ]; then
  echo ""
  echo "Errors:"
  for error in "${ALL_ERRORS[@]}"; do
    echo "  - $error"
  done
fi

# Show warnings
if [ "$TOTAL_WARNINGS" -gt 0 ]; then
  echo ""
  echo "Warnings:"
  for warning in "${ALL_WARNINGS[@]}"; do
    echo "  - $warning"
  done
fi

# Clean up byte-compiled file
rm -f "$HOME/.emacs.d/init.elc"
```
