# Slash Command Automation Rules

## Automatic Multi-Agent Launch for Slash Commands

When executing specific slash commands, **AUTOMATICALLY launch related agents in PARALLEL** without asking for permission.

---

## Command-Specific Agent Launch Rules

### `/plan` Command

**Required Agents (Launch in PARALLEL)**:
1. **`planner` agent**
   - Purpose: Architectural planning and implementation breakdown
   - Launch: IMMEDIATELY when `/plan` is executed
   - Input: Full requirements from $ARGUMENTS

2. **`code-reviewer` agent**
   - Purpose: Pre-implementation security and quality analysis
   - Launch: IMMEDIATELY in parallel with planner
   - Input: Proposed changes and context

**Launch Pattern**:
```javascript
// Launch BOTH agents simultaneously
Task({ subagent_type: "planner", ... })
Task({ subagent_type: "code-reviewer", ... })
```

**Notification to User**:
```markdown
**Auto-launching multi-agent analysis:**
- 🏗️ `planner` agent: Architectural planning
- 🔍 `code-reviewer` agent: Security and quality pre-analysis

Will synthesize both perspectives into comprehensive plan...
```

---

### `/tdd` Command

**Required Agents**:
1. **`planner` agent** (Phase 1: Test Case Planning)
   - Purpose: Analyze requirements and suggest comprehensive test cases
   - Launch: During Phase 1 (Requirements Analysis)
   - Input: Requirements + context

2. **`code-reviewer` agent** (Phase 5: Refactor Phase)
   - Purpose: Review test quality, implementation, and coverage
   - Launch: After implementation, during refactor phase
   - Input: Test code + implementation + coverage report

**Launch Pattern**:
```javascript
// Phase 1: Test planning
Task({ subagent_type: "planner", description: "TDD test case planning", ... })

// Phase 5: Code review (after implementation)
Task({ subagent_type: "code-reviewer", description: "Review TDD implementation", ... })
```

**Notification to User**:
```markdown
**TDD Workflow Initiated:**
- 📋 Phase 1: Launching `planner` agent for test case analysis...
- ✅ Phase 5: Will auto-launch `code-reviewer` agent after implementation
```

---

### `/quality-gate` Command

**Required Agents**:
1. **`code-reviewer` agent**
   - Purpose: Comprehensive quality and security analysis
   - Launch: IMMEDIATELY when `/quality-gate` is executed
   - Input: Target path + detected language/tooling

**Launch Pattern**:
```javascript
Task({ subagent_type: "code-reviewer", description: "Quality gate review", ... })
```

---

### `/refactor-clean` Command (if exists)

**Required Agents (Launch in PARALLEL)**:
1. **`planner` agent**
   - Purpose: Analyze refactoring strategy and identify improvements
   - Launch: IMMEDIATELY

2. **`code-reviewer` agent**
   - Purpose: Review current code for quality issues and technical debt
   - Launch: IMMEDIATELY in parallel

**Launch Pattern**:
```javascript
Task({ subagent_type: "planner", ... })
Task({ subagent_type: "code-reviewer", ... })
```

---

### `/review-pr` Command

**Required Agents (Launch in PARALLEL based on PR content)**:
1. **`code-reviewer` agent** (Always)
   - Purpose: Code quality, security, and best practices review
   - Launch: IMMEDIATELY when `/review-pr` is executed

2. **`doc-updater` agent** (Conditional: if docs changed or breaking changes)
   - Purpose: Documentation completeness and quality review
   - Launch: If documentation files changed OR breaking changes detected

3. **`design-review` agent** (Conditional: if UI changed)
   - Purpose: Design consistency, accessibility, responsive design review
   - Launch: If UI files (*.vue, *.jsx, *.tsx, *.css, *.scss) changed

**Launch Pattern**:
```javascript
// Always launch code-reviewer
Task({ subagent_type: "code-reviewer", ... })

// Conditional launches based on PR content
if (has_doc_changes || has_breaking_changes) {
  Task({ subagent_type: "doc-updater", ... })
}
if (has_ui_changes) {
  Task({ subagent_type: "design-review", ... })
}
```

**Notification**:
```markdown
**Auto-launching PR review agents:**
- 🔍 `code-reviewer` agent: Code quality and security
- 📖 `doc-updater` agent: Documentation completeness (if applicable)
- 🎨 `design-review` agent: UI consistency and accessibility (if applicable)
```

---

### `/optimize` Command

**Required Agents (Launch in PARALLEL)**:
1. **`planner` agent**
   - Purpose: Strategic optimization planning and bottleneck analysis
   - Launch: IMMEDIATELY

2. **`code-reviewer` agent**
   - Purpose: Security-conscious optimization review
   - Launch: IMMEDIATELY in parallel

**Launch Pattern**:
```javascript
Task({ subagent_type: "planner", ... })
Task({ subagent_type: "code-reviewer", ... })
```

---

### `/fix-bug` Command

**Required Agents (Launch in PARALLEL)**:
1. **`planner` agent**
   - Purpose: Root cause analysis and fix strategy
   - Launch: IMMEDIATELY

2. **`code-reviewer` agent**
   - Purpose: Security and quality impact analysis
   - Launch: IMMEDIATELY in parallel

**Post-Fix Agent**:
3. **`code-reviewer` agent** (Post-implementation)
   - Purpose: Verify fix quality and completeness
   - Launch: After fix implementation

**Launch Pattern**:
```javascript
// Phase 1: Root cause analysis (parallel)
Task({ subagent_type: "planner", ... })
Task({ subagent_type: "code-reviewer", ... })

// Phase 2: After fix implementation
Task({ subagent_type: "code-reviewer", description: "Post-fix review", ... })
```

---

### `/document` Command

**Required Agents (Launch in PARALLEL)**:
1. **`general-purpose` agent**
   - Purpose: Deep codebase analysis for documentation extraction
   - Launch: IMMEDIATELY

2. **`doc-updater` agent**
   - Purpose: Documentation quality and consistency analysis
   - Launch: IMMEDIATELY in parallel

**Post-Generation Agent**:
3. **`doc-updater` agent** (Post-generation)
   - Purpose: Quality review of generated documentation
   - Launch: After documentation generation

**Launch Pattern**:
```javascript
// Phase 1: Analysis (parallel)
Task({ subagent_type: "general-purpose", ... })
Task({ subagent_type: "doc-updater", ... })

// Phase 2: After documentation generation
Task({ subagent_type: "doc-updater", description: "Documentation quality review", ... })
```

---

### `/quality-gate` Command (Enhanced)

**Required Agents (Launch in PARALLEL)**:
1. **`code-reviewer` agent**
   - Purpose: Comprehensive code quality and security review
   - Launch: IMMEDIATELY

2. **`doc-updater` agent**
   - Purpose: Documentation quality review
   - Launch: IMMEDIATELY in parallel

**Launch Pattern**:
```javascript
Task({ subagent_type: "code-reviewer", ... })
Task({ subagent_type: "doc-updater", ... })
```

---

### `/refactor-clean` Command (Enhanced)

**Required Agents (Launch in PARALLEL)**:
1. **`planner` agent**
   - Purpose: Refactoring strategy and prioritization
   - Launch: IMMEDIATELY

2. **`code-reviewer` agent**
   - Purpose: Pre-refactoring code quality and safety analysis
   - Launch: IMMEDIATELY in parallel

**Post-Refactoring Agent**:
3. **`code-reviewer` agent** (Post-refactoring)
   - Purpose: Verify refactoring results and quality improvement
   - Launch: After refactoring completion

**Launch Pattern**:
```javascript
// Phase 1: Strategic analysis (parallel)
Task({ subagent_type: "planner", ... })
Task({ subagent_type: "code-reviewer", ... })

// Phase 2: After refactoring
Task({ subagent_type: "code-reviewer", description: "Post-refactoring review", ... })
```

---

### `/update-architecture` Command

**Required Agents**:
1. **`doc-updater` agent**
   - Purpose: Analyze project structure and generate architecture documentation
   - Launch: IMMEDIATELY when `/update-architecture` is executed

**What it generates:**
- `.claude/architecture/overview.md` - System architecture with Mermaid diagrams
- `.claude/architecture/components.md` - Component catalog
- `.claude/architecture/data-flow.md` - Data flow diagrams
- `.claude/architecture/decisions.md` - Architectural Decision Records

**Launch Pattern**:
```javascript
Task({
  subagent_type: "doc-updater",
  description: "Generate architecture documentation",
  prompt: "Analyze project structure and generate comprehensive architecture documentation..."
})
```

---

### `/update-database` Command

**Required Agents**:
1. **`doc-updater` agent**
   - Purpose: Extract database schema and generate database documentation
   - Launch: IMMEDIATELY when `/update-database` is executed

**What it generates:**
- `.claude/database/schema.md` - Complete schema with all tables
- `.claude/database/erd.md` - Entity-Relationship Diagram (Mermaid)
- `.claude/database/migrations.md` - Migration history
- `.claude/database/queries.md` - Common queries

**Launch Pattern**:
```javascript
Task({
  subagent_type: "doc-updater",
  description: "Generate database documentation",
  prompt: "Analyze database structure and generate comprehensive database documentation..."
})
```

---

### Custom Commands with `multi-` Prefix

**Any command starting with `multi-`** (e.g., `/multi-api`, `/multi-plan-vue-laravel`) signals multi-agent workflow.

**Default Agents**:
1. **`planner` agent** - Planning phase
2. **`code-reviewer` agent** - Quality/security review

**Launch**: AUTOMATICALLY in parallel

---

## General Multi-Agent Launch Conditions

### Always Launch `code-reviewer` After Significant Code Changes

**Trigger Conditions**:
- After implementing new features (3+ files modified)
- After refactoring (significant line changes)
- Before committing changes
- User requests review ("review my code", "check my changes")

**Launch Automatically** (no permission needed):
```javascript
Task({
  subagent_type: "code-reviewer",
  description: "Post-implementation review",
  prompt: "Review recent code changes for quality, security, and best practices..."
})
```

**Notification**:
```markdown
🔍 Auto-launching `code-reviewer` agent to review recent changes...
```

---

### Always Launch `planner` for Complex Feature Requests

**Trigger Conditions**:
- User requests feature implementation with 5+ steps
- User mentions "architecture", "design", "plan", "計画", "設計"
- Complex requirements with multiple components

**Launch Automatically**:
```javascript
Task({
  subagent_type: "planner",
  description: "Feature planning",
  prompt: "Analyze requirements and create implementation plan..."
})
```

---

### Always Launch `interviewer` for Vague Requests

**Trigger Conditions**:
- Requirements are unclear or underspecified
- User says "何か作りたい" but unclear WHAT to build
- Multiple possible interpretations of the request

**Launch Automatically**:
```javascript
Task({
  subagent_type: "interviewer",
  description: "Requirements clarification",
  prompt: "Clarify user requirements through structured questioning..."
})
```

---

## Parallel Execution Rules

### MUST Launch in Parallel When:
- Agents analyze **independent aspects** (planning + security review)
- No dependencies between agent tasks
- Faster completion is beneficial

**Example (Parallel)**:
```javascript
// CORRECT: Launch simultaneously
Task({ subagent_type: "planner", ... })
Task({ subagent_type: "code-reviewer", ... })
// Both tasks run concurrently
```

### MUST Launch Sequentially When:
- Second agent **depends on output** of first agent
- Workflow has explicit phases (TDD: plan tests → implement → review)

**Example (Sequential)**:
```javascript
// CORRECT: Launch planner first
Task({ subagent_type: "planner", ... })
// Wait for result...
// Then launch reviewer based on planner output
Task({ subagent_type: "code-reviewer", ... })
```

---

## User Notification Format

**Before launching agents**:
```markdown
**Auto-launching multi-agent workflow:**
- 🏗️ `planner` agent: [Purpose]
- 🔍 `code-reviewer` agent: [Purpose]
- [Additional agents if any]

This will provide comprehensive analysis from multiple perspectives...
```

**After agents complete**:
```markdown
**Multi-agent analysis complete:**
✅ `planner` agent: [Key findings]
✅ `code-reviewer` agent: [Key findings]

Synthesizing recommendations...
```

---

## Exception: When NOT to Auto-Launch

**Do NOT auto-launch agents when:**
- User explicitly says "no agents", "just answer directly", "don't launch agents"
- Simple question that can be answered directly
- Information is already available (no analysis needed)
- User is exploring/learning (educational context)

**Example**:
```
User: "Explain how /plan works"
→ Do NOT launch planner agent
→ Just explain the command directly
```

---

## Integration with Post-Tool Hooks

**Post-Implementation Auto-Launch**:

After significant code changes (Edit/Write), check if `code-reviewer` should auto-launch:

```javascript
// In PostToolUse hook (conceptual)
if (files_modified >= 3 || lines_changed >= 100) {
  console.error('[Auto-Agent] Launching code-reviewer for recent changes...')
  // Trigger code-reviewer agent
}
```

**NOTE**: Actual hook implementation should use `.claude/hooks/scripts/` with Node.js

---

## Success Metrics

**Multi-agent automation is successful when:**
- ✅ Reduced bugs and logical errors (agents catch issues early)
- ✅ Comprehensive analysis (multiple perspectives)
- ✅ Faster workflows (parallel execution)
- ✅ Consistent quality (automated reviews)
- ✅ User doesn't need to manually request agents

---

## Maintenance

**When adding new slash commands**:
- [ ] Document command in this file
- [ ] Specify which agents to auto-launch
- [ ] Define launch timing (parallel vs sequential)
- [ ] Add user notification template
- [ ] Test multi-agent workflow

**When adding new agents**:
- [ ] Update relevant slash command rules
- [ ] Add to agent registry (`.claude/agents/AGENTS.md`)
- [ ] Document triggers in `agent-patterns.md`
- [ ] Update `agent-automation.md` if needed
