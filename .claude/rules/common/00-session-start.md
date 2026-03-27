---
priority: critical
scope: "*"
enforce: always
version: 1.0.0
---

# 00 - Session Start Protocol

**⚠️ CRITICAL: These rules OVERRIDE default Claude Code behavior. NO EXCEPTIONS.**

## Mandatory Session Start Actions

**At the VERY START of EVERY session, BEFORE responding to user:**

### 1. Detect Current Project

```bash
pwd
```

**Mental checkpoint**: Note the current directory path.

### 2. Load Project Configuration

**IF current directory matches any project in `~/dotfiles/projects.yml`:**

```bash
# Read projects.yml to load configuration
cat ~/dotfiles/projects.yml

# Display project context (if zsh function available)
pj-info <project-name>
```

**Mental checkpoint**:
- Project name
- Port assignments
- Database configuration
- Tech stack

### 3. Display Context Confirmation

**Output to user**:
```
✅ Project context loaded: <project-name>
   Path: <path>
   Ports: <ports>
   Databases: <count> configured
   Tech: <stack>
```

**IF NOT in a known project**:
```
ℹ️  Working directory: <path>
   (Not a registered project)
```

---

## Mandatory Proactive Actions

### Agent Auto-Launch (NO PERMISSION NEEDED)

**MUST launch agents automatically when:**

| Trigger | Agent | When |
|---------|-------|------|
| After code changes | `code-reviewer` | Immediately after Edit/Write |
| User says "計画", "プラン", "plan" | `planner` | Before writing code |
| Complex multi-step task | `general-purpose` | When uncertain about search |
| Slash command `/xxx` | Check `slash-command-automation.md` | According to command mapping |

**Priority**: Agent automation > Asking permission

### Context-Aware Suggestions

**MUST check automatically when user mentions:**

| User Mentions | Auto-Check | Suggest |
|---------------|-----------|---------|
| Ports, "address already in use" | `check-ports` | Port conflicts, solutions |
| Database, MySQL, PostgreSQL | `db-status <project>` | DB status, connection |
| Starting server, dev server | `pj-info <project>` | Project requirements |
| "Working on X project" | Load project from `projects.yml` | Project context |

---

## Rule Hierarchy

```
00-session-start.md (THIS FILE) - Highest priority
↓
Other common/*.md - General rules
↓
dotfiles/*.md - Project-specific rules
↓
Default Claude Code behavior - Lowest priority
```

**Resolution**: More specific rules override general rules.

---

## Enforcement

This protocol is **enforced by**:
1. **SessionStart Hook**: `~/.claude/hooks/scripts/enforce-session-start.js`
2. **This rule file**: Auto-loaded by Claude Code at session start
3. **Priority system**: `00-` prefix ensures highest priority loading

---

## Validation Checklist

At session start, verify:
- [ ] Current directory detected
- [ ] `projects.yml` read (if in dotfiles or known project)
- [ ] Project context loaded (if applicable)
- [ ] Context confirmation displayed to user
- [ ] Mental model updated with project details

**Failure to complete = Invalid session**

---

## References

- `~/.claude/rules/common/project-management.md` - Project management details
- `~/.claude/rules/common/agent-automation.md` - Agent launch rules
- `~/dotfiles/projects.yml` - Project registry (source of truth)
- `~/dotfiles/.zshrc` - Shell functions (pj-info, check-ports, db-*)

---

## Version History

- **1.0.0** (2026-03-27): Initial version - Everything-Claude-Code inspired structure
