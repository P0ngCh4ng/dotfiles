# Cage EPERM Error - RESOLVED (2026-03-22)

## Problem Summary

**Symptom**: EPERM errors when starting Claude Code sessions in certain projects
- **dotfiles project**: Works normally (session files created)
- **pon project**: Failed with EPERM (0 session files, cannot write)
- **Other projects**: Also affected

**Error Message**:
```
Error: EPERM: operation not permitted, open '/Users/pongchang/.claude/projects/-Users-pongchang-pon/[uuid].jsonl'
```

**Timeline**: 2026-03-22, multiple hours of investigation

## Root Cause

**Symlink resolution issue**:
```bash
$ ls -la ~/.claude
lrwxr-xr-x  ~/.claude -> /Users/pongchang/dotfiles/.claude
```

- `.claude` is a **symlink** to `dotfiles/.claude`
- `presets.yaml` allowed `/Users/pongchang/.claude`
- cage **did not resolve the symlink** to the actual path
- Writes to `/Users/pongchang/dotfiles/.claude/projects/` were **blocked**

**Why dotfiles worked initially**:
- The current session was running **inside dotfiles directory**
- Current directory (`.`) was allowed in cage config
- So writes worked accidentally

**Why other projects failed**:
- Running from `~/pon` or other directories
- cage blocked access to the actual symlink target
- EPERM on file creation

## Investigation Journey

### 1. Initial Hypothesis: Nested cage execution (INCORRECT)
- Suspected `IN_CAGE` environment variable persistence
- Implemented shell conditional in elisp to prevent nesting
- iTerm2 completely restarted to clear environment variables
- **Result**: `IN_CAGE` empty, but EPERM persisted

### 2. Second Hypothesis: macOS SIP blocking sandbox_apply (PARTIALLY CORRECT)
- Testing revealed: `cage echo "test"` → `sandbox-exec: sandbox_apply: Operation not permitted`
- Concluded cage was completely blocked by macOS
- Disabled cage in configuration
- **Result**: This was a red herring - the test itself was wrong

### 3. Key Discovery: Different error messages
```bash
# Test command (failed):
$ cage ... echo "test"
sandbox-exec: sandbox_apply: Operation not permitted

# Actual Claude Code (different error):
$ cage ... claude --dangerously-skip-permissions
Error: EPERM: operation not permitted, open '.../.claude/projects/.../[uuid].jsonl'
# Note: NO "sandbox_apply" error!
```

- cage **WAS working** for Claude Code
- sandbox **WAS applied** successfully
- But file writes were **blocked by sandbox rules**

### 4. Final Discovery: Symlink issue
```bash
$ readlink ~/.claude
/Users/pongchang/dotfiles/.claude

$ cage -dry-run -preset claude-code echo "test"
# Showed: Allow writes to /Users/pongchang/.claude
# But actual path is: /Users/pongchang/dotfiles/.claude
```

## Solution

**File**: `~/.config/cage/presets.yaml`

```yaml
presets:
  claude-code:
    allow:
      # Before (broken):
      - "/Users/pongchang/.claude"

      # After (fixed):
      - path: "/Users/pongchang/.claude"
        eval-symlinks: true  # ← Added this
```

**Effect**:
- cage now resolves symlinks
- Allows writes to both:
  - `/Users/pongchang/.claude` (symlink)
  - `/Users/pongchang/dotfiles/.claude` (actual path)

## Files Modified

1. **`.config/cage/presets.yaml`** (line 10-11):
   - Added `eval-symlinks: true` to `.claude` path

2. **`.emacs.d/elisp/claude-code-projects.el`** (line 74):
   - Kept `claude-code-projects-use-cage t` (enabled)

3. **`CLAUDE.md`** (lines 54-62, 118-151):
   - Updated cage status to ENABLED
   - Updated troubleshooting section with symlink solution

4. **`.serena/memories/troubleshooting/cage-eperm-2026-03-22.md`**:
   - This resolution document

## Verification

```bash
# Test 1: Write to .claude/projects via cage
cd ~/pon
cage -config "$HOME/.config/cage/presets.yaml" -preset claude-code \
  bash -c "touch ~/.claude/projects/test.txt && rm ~/.claude/projects/test.txt"
# Result: SUCCESS (no EPERM)

# Test 2: Launch Claude Code in pon project
cd ~/pon
cage -config "$HOME/.config/cage/presets.yaml" -preset claude-code \
  claude --dangerously-skip-permissions
# Result: SUCCESS (session files created in ~/.claude/projects/-Users-pongchang-pon/)
```

## Key Learnings

1. **Symlinks and sandboxing**:
   - Sandboxes often don't automatically resolve symlinks
   - Explicitly enable `eval-symlinks` when using symlinked paths
   - Test actual file operations, not just command execution

2. **Error message interpretation**:
   - `sandbox-exec: sandbox_apply: Operation not permitted` → sandbox initialization failed
   - `EPERM: operation not permitted, open '...'` → sandbox active, but file access denied
   - **Different root causes** despite similar "operation not permitted" wording

3. **Debugging methodology**:
   - Check running processes to verify actual execution path
   - Compare error messages carefully (verbatim comparison)
   - Test with minimal reproduction (not just the full application)
   - Verify assumptions about symlinks and file paths

4. **macOS sandbox behavior**:
   - `sandbox-exec` works fine with proper entitlements
   - The tool is deprecated but still functional
   - SIP doesn't prevent all sandbox-exec usage
   - Some test commands fail while real commands work

## Status

**RESOLVED**: 2026-03-22 21:00 JST

- ✅ Root cause identified: symlink resolution issue
- ✅ Fix applied: `eval-symlinks: true` in cage config
- ✅ Verification complete: All projects work with cage enabled
- ✅ Documentation updated: CLAUDE.md and memory files
- ⏳ Pending: Commit changes to repository

## Related Files

- Configuration: `~/.config/cage/presets.yaml`
- Emacs package: `~/.emacs.d/elisp/claude-code-projects.el`
- Documentation: `~/dotfiles/CLAUDE.md`
- Symlink: `~/.claude -> ~/dotfiles/.claude`
