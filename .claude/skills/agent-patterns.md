# Agent Patterns and Examples

Detailed examples and patterns for agent usage in Claude Code.

## Agent Selection Principles

### 1. Specialization Priority
When domain-specific agents exist, prefer them over general-purpose agents.

**Examples**:
- Emacs config optimization → `emacs-optimizer` (specialized) > general analysis agent
- Code quality review → `code-reviewer` (specialized) > general review
- Test implementation → `tdd-guide` (specialized) > generic coding agent

### 2. Launch Based on Task Complexity
- **Simple questions**: No agent needed, answer directly
- **Complex analysis/optimization**: Launch specialized agent
- **Multi-step tasks**: Launch multiple agents in parallel

### 3. User Experience Optimization
- Provide brief explanation before launch
- Clarify execution scope and expected results
- Provide summary after completion

## Agent Launch Notification Format

Use this format when launching agents:

```markdown
Launching `agent-name` agent for [brief description].

**Execution Scope**:
- Task 1
- Task 2
- Task 3

Will present specific [deliverable] after analysis.
```

### Example: Emacs Optimizer Launch

```markdown
Launching `emacs-optimizer` agent for comprehensive Emacs config analysis.

**Execution Scope**:
- Performance analysis of init.el
- Detect redundant/unused packages
- Startup time optimization suggestions

Will present specific improvement proposals after analysis.
```

### Example: Code Review Launch

```markdown
Launching `code-reviewer` agent for quality and security analysis.

**Execution Scope**:
- Security vulnerabilities scan
- Code quality assessment
- Best practices verification

Will provide detailed review report with specific recommendations.
```

## Parallel Execution Patterns

### Good: Parallel Execution

Launch multiple agents concurrently when tasks are independent:

```
1. emacs-optimizer: analyze init.el
2. code-reviewer: review newly added elisp
3. security-scanner: check for vulnerabilities
```

**Benefits**:
- Faster completion
- Independent analysis
- No blocking dependencies

### Bad: Unnecessary Sequential Execution

Avoid sequential execution when tasks are independent:

```
1. Run emacs-optimizer first
2. Wait for completion
3. Then run code-reviewer
```

**Why Bad**:
- Slower overall execution
- Wasted time waiting
- No technical dependency requiring sequence

### Parallel Execution Conditions

Tasks can be executed in parallel when:
- No dependencies between tasks
- Each task generates independent outputs
- Execution order doesn't affect results
- No shared state modifications

## Specific Agent Trigger Examples

### Emacs Optimizer (`emacs-optimizer`)

**Trigger Keywords**:
- "Emacs slow", "startup time", "performance"
- "package cleanup", "redundant", "unused packages"
- "init.el optimize", "elisp improve"

**Launch Conditions**:
```
IF (
  user_request.contains("Emacs") AND
  (user_request.contains("slow|optimize") OR
   user_request.contains("startup|performance") OR
   user_request.contains("package|redundant"))
) THEN
  launch_agent("emacs-optimizer")
END
```

**Examples**:
- ✅ "Emacs startup is slow, need improvement" → launch emacs-optimizer
- ✅ "Optimize init.el" → launch emacs-optimizer
- ✅ "Remove unused packages" → launch emacs-optimizer
- ❌ "What are Emacs keybindings?" → don't launch (simple question)

### Code Reviewer (`code-reviewer`)

**Trigger Keywords**:
- "review", "quality check", "security scan"
- "best practices", "code smell"
- After significant code changes

**Examples**:
- ✅ After implementing new feature → launch automatically
- ✅ "Review my recent changes" → launch code-reviewer
- ❌ "What does this function do?" → don't launch (simple explanation)

## Prohibited Launch Cases

**Do NOT** launch agents for:

1. **Simple information retrieval**: File content checks, explaining known info
2. **Sufficient info already available**: No need for additional analysis
3. **Explicit user rejection**: Instructions like "no agent needed", "just answer directly"

### Examples of When NOT to Launch

- ❌ "What does this error mean?" → Direct explanation sufficient
- ❌ "Show me the code for function X" → Use Read tool directly
- ❌ "List my project files" → Use ls or Glob directly

## Agent Registry Management

### Adding New Agent

**Required Tasks**:
- [ ] Create new agent definition file (`.md`) in `~/.claude/agents/`
- [ ] Add new agent section to `.claude/agents/AGENTS.md`
- [ ] Document purpose, triggers, available tools, and model
- [ ] Add trigger conditions to rules (`agent-automation.md`)

### Removing Agent

**Required Tasks**:
- [ ] Delete agent definition file (`.md`)
- [ ] Remove section from `.claude/agents/AGENTS.md`
- [ ] Remove trigger conditions from rules (`agent-automation.md`)
- [ ] Document removal reason in git commit message

### Modifying Agent

**Required Tasks**:
- [ ] Update `.claude/agents/AGENTS.md` per changes
- [ ] Update trigger conditions in rules if triggers changed
- [ ] Test agent with sample tasks to verify behavior

### Registry Verification

After agent operations, verify consistency:

```bash
# Check if agent file count matches AGENTS.md entry count
ls .claude/agents/*.md | grep -v AGENTS.md | wc -l
grep "^### " .claude/agents/AGENTS.md | wc -l
```

If counts mismatch, fix immediately by updating AGENTS.md or adding/removing agent files.
