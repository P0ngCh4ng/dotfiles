# Global Rules Restructure - Migration Summary

**Date**: 2026-03-27
**Status**: ✅ Complete
**Inspired by**: [everything-claude-code](https://github.com/affaan-m/everything-claude-code)

---

## 🎯 What Changed

### Before (Flat Structure)
```
~/.claude/rules/
├── agent-automation.md
├── project-management.md
├── database-management.md
├── emacs-environment.md
├── ...
└── common/  # Only 3 basic files
```

**Problem**: Rules were not enforced, just "recommendations"

### After (Hierarchical Structure)
```
~/.claude/rules/
├── common/                           # All projects (mandatory)
│   ├── 00-session-start.md          # ⭐ NEW: Highest priority
│   ├── agent-automation.md
│   ├── project-management.md
│   ├── bug-prevention.md
│   ├── auto-documentation.md
│   ├── slash-command-automation.md
│   ├── coding-style.md
│   ├── git-workflow.md
│   └── testing.md
└── dotfiles/                         # Dotfiles-specific
    ├── emacs-environment.md
    ├── database-management.md
    └── verification-strategy.md
```

**Solution**: Rules are now ENFORCED by hooks

---

## 🪝 New Enforcement Mechanisms

### 1. SessionStart Hook
**File**: `~/.claude/hooks/scripts/enforce-session-start.js`

**What it does**:
- Detects current project from `pwd`
- Reads `~/dotfiles/projects.yml`
- Displays project context automatically
- Shows ports, databases, tech stack

**Example output**:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚙️  SESSION START PROTOCOL (Auto-enforced by hooks)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📂 Current Directory: /Users/pongchang/dotfiles

✅ Project Context Loaded: dotfiles
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   Project: dotfiles
   Path: ~/dotfiles
   Description: Personal dotfiles and PC management hub
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 REMINDER: Follow rules in ~/.claude/rules/common/00-session-start.md
   • Auto-launch agents when conditions match
   • Check ports/databases proactively
   • Use project context for suggestions
```

### 2. PostToolUse Hook
**File**: `~/.claude/hooks/scripts/enforce-agent-launch.js`

**What it does**:
- Triggers after Edit/Write/MultiEdit
- Reminds Claude to launch `code-reviewer`
- 5-minute cooldown to avoid spam

**Example output**:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🤖 AGENT AUTO-LAUNCH REMINDER
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

⚠️  Code was modified (Edit tool used)

💡 According to ~/.claude/rules/common/00-session-start.md:
   You SHOULD launch the `code-reviewer` agent automatically
   (No permission needed - auto-launch is REQUIRED)
```

### 3. Priority System
**File naming convention**:
- `00-xxx.md` = Critical (highest priority)
- `01-xxx.md` = High priority
- `xxx.md` = Normal priority

**Rule hierarchy**:
```
00-session-start.md (CRITICAL)
    ↓ overrides
common/*.md (General)
    ↓ overridden by
dotfiles/*.md (Project-specific)
```

---

## 📝 Key New Files

### `~/.claude/rules/common/00-session-start.md`
The most important file - defines MANDATORY behavior:
- Session start protocol
- Agent auto-launch rules
- Context-aware suggestions
- Rule hierarchy

### `~/.claude/hooks/hooks.json`
Updated with new hooks:
```json
{
  "SessionStart": [
    {
      "description": "⚠️ CRITICAL: Load project context from projects.yml"
    }
  ],
  "PostToolUse": [
    {
      "description": "⚠️ REMINDER: Auto-launch code-reviewer after code changes"
    }
  ]
}
```

---

## ✅ Verification

### Test SessionStart Hook
```bash
cd ~/dotfiles
node ~/.claude/hooks/scripts/enforce-session-start.js
```

### Test PostToolUse Hook
```bash
TOOL_NAME="Edit" node ~/.claude/hooks/scripts/enforce-agent-launch.js
```

### Validate hooks.json
```bash
node -e "JSON.parse(require('fs').readFileSync('$HOME/.claude/hooks/hooks.json', 'utf-8'))"
```

---

## 🔄 Rollback Instructions

If you need to revert to the old structure:

```bash
# Restore from backup
rm -rf ~/.claude/rules
cp -r ~/.claude/backups/rules-20260327-170057 ~/.claude/rules

# Revert hooks.json
git -C ~/.claude checkout hooks/hooks.json

# Remove new hook scripts
rm ~/.claude/hooks/scripts/enforce-session-start.js
rm ~/.claude/hooks/scripts/enforce-agent-launch.js
```

---

## 📚 References

- **Inspiration**: [everything-claude-code](https://github.com/affaan-m/everything-claude-code)
- **Plan**: `~/.claude/rules/RESTRUCTURE-PLAN.md`
- **Documentation**: `~/dotfiles/CLAUDE.md` (updated)
- **Global CLAUDE.md**: `~/.claude/CLAUDE.md` (unchanged)

---

## 🎉 Expected Behavior

**From now on, Claude Code will:**

1. ✅ **Automatically load project context** at session start
2. ✅ **Auto-launch agents** when conditions match (no permission needed)
3. ✅ **Proactively check** ports/databases when user mentions them
4. ✅ **Follow rules consistently** (enforced by hooks)

**No more "forgetting" to:**
- Read projects.yml
- Launch code-reviewer
- Check project configuration
- Follow agent automation rules

---

## 🚀 Next Steps

1. Start a new Claude Code session to see the hooks in action
2. Make a code change to trigger the PostToolUse reminder
3. Monitor hook output in stderr
4. Adjust cooldown/behavior if needed

---

**Backup Location**: `~/.claude/backups/rules-20260327-170057/`

**Questions?** See:
- `~/.claude/rules/RESTRUCTURE-PLAN.md`
- `~/.claude/rules/common/00-session-start.md`
- `~/dotfiles/CLAUDE.md`
