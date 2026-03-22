# Claude Code + Cage EPERM Error Troubleshooting

## Problem
```
Error: EPERM: operation not permitted, open '/Users/pongchang/.claude/projects/-Users-pongchang-pon/[uuid].jsonl'
```

## Root Cause
**macOS security restrictions** prevent cage from applying sandbox profiles:

1. cage attempts to apply sandbox profile using `sandbox-exec`
2. macOS kernel blocks `sandbox_apply` system call (SIP/security policy)
3. Error: `sandbox-exec: sandbox_apply: Operation not permitted`
4. cage fails → Claude Code can't write to `~/.claude/projects/`
5. Affects **both** iTerm2 and Emacs (system-wide issue)

### Previous Theory (Incorrect)
Initially thought to be nested cage execution, but testing revealed the actual cause:
- cage configuration is correct (verified with `-dry-run`)
- `~/.claude` has proper write permissions in sandbox profile
- **BUT** macOS blocks the sandbox application itself

## Detection
```bash
# Check if currently in cage
echo $IN_CAGE  # If "1", you're inside cage
```

**CRITICAL**: If this Claude Code session shows `IN_CAGE=1`, the problem **cannot be solved from within this session**. The entire Emacs process has inherited the cage environment and must be completely restarted.

## Solution

### Permanent Fix (Cage Disabled)
Cage has been **disabled system-wide** due to macOS restrictions:

**Files Modified**:
1. `.zshrc` (line 155):
   ```bash
   alias claude='CLAUDE_CODE_DISABLE_ITERM2=1 ~/homebrew/bin/claude --dangerously-skip-permissions'
   alias claude-with-cage='...'  # Preserved for future use, currently broken
   ```

2. `.emacs.d/elisp/claude-code-projects.el` (line 74):
   ```elisp
   (defcustom claude-code-projects-use-cage nil  ; Changed from t
     "Currently disabled due to macOS sandbox_apply: Operation not permitted.")
   ```

3. `CLAUDE.md`: Updated documentation with new troubleshooting section

**Apply Changes**:
```bash
# 1. Reload shell
source ~/.zshrc

# 2. In Emacs
M-x load-file RET ~/.emacs.d/elisp/claude-code-projects.el RET
M-x claude-code-kill-all-sessions RET

# 3. Launch new session (cage-free)
C-c C-p  # Select project
```

### Verification
Test that cage is causing the issue:
```bash
# This should succeed (direct execution)
cd ~/pon
~/homebrew/bin/claude --version

# This should fail (cage execution)
cd ~/pon
cage -config ~/.config/cage/presets.yaml sh -c "touch ~/.claude/test.txt"
# Expected: "sandbox-exec: sandbox_apply: Operation not permitted"
```

### Future Re-enablement (if macOS restrictions are resolved)
```elisp
M-x customize-variable RET claude-code-projects-use-cage RET
;; Set to 't', Apply and Save
;; NOTE: Will cause EPERM errors until macOS issue is resolved
```

## Optional Cleanup

### Clean Old Sessions
```bash
cd ~/.claude/projects/-Users-pongchang-[project]
find . -name "*.jsonl" -mtime +7 -delete
find . -type d -empty -delete
```

### Fix Permissions
```bash
chmod 700 ~/.claude/projects/-Users-pongchang-[project]
```

## Prevention Best Practices
1. **Keep cage enabled** - automatic detection handles nesting
2. **Restart Emacs periodically** - clears accumulated env vars
3. **Launch from `/Applications/Emacs.app`** - not from terminal in cage

## Technical Details

### Environment Variable Flow
```
Terminal (cage) → Emacs (exec-path-from-shell) → vterm → Claude Code
         ↓                    ↓                      ↓
    IN_CAGE=1           imports env           inherits IN_CAGE=1
```

### Why EPERM Occurs
- Cage restricts filesystem access via sandboxing
- Nested cage creates conflicting permission boundaries
- Inner cage can't write to paths outer cage allowed
- Result: EPERM on `.claude/projects/` writes

## Related Files
- `.emacs.d/elisp/claude-code-projects.el` - Cage integration logic
- `.emacs.d/init.el` - Cage configuration
- `~/.config/cage/presets.yaml` - Cage permissions config
- `CLAUDE.md` - Full documentation with troubleshooting section

## Date
2026-03-22