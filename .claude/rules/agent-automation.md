# Agent Automation Rules

## Auto-Launch Policy

Launch agents automatically when trigger conditions match:

### When to Launch Agents

**ALWAYS launch when:**
- User mentions specific trigger keywords (see `~/.claude/skills/agent-patterns.md`)
- After significant code changes (launch `code-reviewer`)
- Complex multi-step tasks requiring specialized analysis
- **Slash commands executed** (see `~/.claude/rules/slash-command-automation.md`)

**Examples**:
- "Emacs slow" → `emacs-optimizer`
- "Review my code" → `code-reviewer`
- After writing new feature → `code-reviewer` (proactive)
- **`/plan` command** → auto-launch `planner` + `code-reviewer` (parallel)
- **`/tdd` command** → auto-launch `planner` → (implement) → `code-reviewer` (sequential)

### When NOT to Launch

**NEVER launch for:**
- Simple questions (direct answer sufficient)
- Information already available
- User explicitly says "no agent needed"

## Parallel Execution

**ALWAYS execute independent tasks in parallel**:
- ✅ Launch multiple agents concurrently if no dependencies
- ❌ Avoid sequential execution when tasks are independent

**Conditions for parallel execution:**
- No dependencies between tasks
- Each task generates independent outputs
- Execution order doesn't affect results

**Multi-agent orchestration patterns**:
- See `~/.claude/skills/multi-agent-orchestration/SKILL.md` for comprehensive patterns and examples

## Agent Registry Maintenance

**MUST update `.claude/agents/AGENTS.md` when:**
- [ ] Adding agent: Create file + update registry + add triggers to this file
- [ ] Removing agent: Delete file + update registry + remove triggers
- [ ] Modifying agent: Update registry + update triggers if changed

**Verify after changes:**
```bash
ls .claude/agents/*.md | grep -v AGENTS.md | wc -l
grep "^### " .claude/agents/AGENTS.md | wc -l
```

Fix immediately if counts mismatch.

## Bug Prevention Integration

**Multi-agent verification for bug prevention**:
- Launch `planner` + `code-reviewer` in parallel during planning phase
- Catches bugs BEFORE implementation (cheaper to fix)
- See `~/.claude/rules/bug-prevention.md` for comprehensive bug prevention strategies

## References

For detailed information, see:
- `~/.claude/skills/agent-patterns.md` - Agent usage patterns and examples
- `~/.claude/rules/slash-command-automation.md` - Automatic agent launch for slash commands
- `~/.claude/skills/multi-agent-orchestration/SKILL.md` - Multi-agent orchestration patterns
- `~/.claude/rules/bug-prevention.md` - Bug prevention through multi-agent verification
