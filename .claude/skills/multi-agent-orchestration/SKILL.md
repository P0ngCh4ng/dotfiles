# Multi-Agent Orchestration Skill

**Skill Name**: Multi-Agent Orchestration
**Purpose**: Coordinate multiple specialized agents for comprehensive analysis, planning, and implementation
**Complexity**: Advanced
**Impact**: High (reduces bugs, improves quality, accelerates workflows)

---

## Core Concept

**Multi-agent orchestration** involves launching multiple specialized agents **in parallel or sequentially** to:
1. Analyze problems from multiple perspectives
2. Catch bugs and logical errors early
3. Ensure comprehensive coverage (architecture + security + quality)
4. Reduce manual oversight burden

---

## When to Use Multi-Agent Orchestration

### Use Cases

1. **Complex Feature Planning**
   - Agents: `planner` + `code-reviewer`
   - Pattern: Parallel launch for architectural planning + security pre-analysis

2. **Test-Driven Development**
   - Agents: `planner` (test cases) → `code-reviewer` (implementation review)
   - Pattern: Sequential (plan tests first, review implementation after)

3. **Quality Assurance**
   - Agents: `code-reviewer` + `doc-updater`
   - Pattern: Parallel (review code + update docs simultaneously)

4. **Refactoring**
   - Agents: `planner` + `code-reviewer`
   - Pattern: Parallel (identify improvements + review current code)

5. **API Development**
   - External models: Codex (backend logic) + Gemini (developer experience)
   - Pattern: Parallel analysis → synthesized plan

---

## Orchestration Patterns

### Pattern 1: Parallel Analysis (Independent Perspectives)

**When to Use**: Agents analyze **different aspects** of the same problem

**Example**: Feature planning with multi-agent review

```javascript
// Launch planner and code-reviewer simultaneously
Task({
  subagent_type: "planner",
  description: "Architectural planning",
  prompt: "Analyze requirements and create implementation plan for [feature]..."
})

Task({
  subagent_type: "code-reviewer",
  description: "Security pre-analysis",
  prompt: "Review proposed changes for security, quality, and best practices..."
})

// Both agents run concurrently
// Synthesize results after both complete
```

**Benefits**:
- ⚡ Faster completion (concurrent execution)
- 🔍 Comprehensive coverage (multiple perspectives)
- 🛡️ Early risk detection (security + architecture)

**Use Cases**:
- `/plan` command: planner + code-reviewer
- `/refactor-clean`: planner + code-reviewer
- Quality gate: code-reviewer + doc-updater

---

### Pattern 2: Sequential Pipeline (Dependent Stages)

**When to Use**: Second agent **depends on output** of first agent

**Example**: TDD workflow

```javascript
// Stage 1: Plan test cases
Task({
  subagent_type: "planner",
  description: "TDD test case planning",
  prompt: "Suggest comprehensive test cases for [feature]..."
})

// Wait for planner to complete...
// Use planner output to write tests
// Implement code to pass tests

// Stage 2: Review implementation
Task({
  subagent_type: "code-reviewer",
  description: "Review TDD implementation",
  prompt: "Review tests and implementation for quality and coverage..."
})
```

**Benefits**:
- 📋 Structured workflow (clear phases)
- ✅ Quality gates (review before proceeding)
- 🔄 Iterative refinement (feedback loops)

**Use Cases**:
- `/tdd` command: planner → (implement) → code-reviewer
- Multi-step features: interviewer → planner → (implement) → code-reviewer

---

### Pattern 3: Feedback Loop (Iterative Refinement)

**When to Use**: Agent output requires iteration and improvement

**Example**: Configuration verification with auto-fix

```javascript
// Iteration 1: Verify and fix
Task({
  subagent_type: "emacs-verifier",
  description: "Verify Emacs config",
  prompt: "Verify and auto-fix Emacs configuration..."
})

// Check if errors remain
// If errors > 0, iterate again (max 10 iterations)
// Continue until 0 errors and 0 warnings
```

**Benefits**:
- 🔁 Continuous improvement (iterate until clean)
- 🤖 Autonomous fixing (no manual intervention)
- 🎯 Clear success criteria (0 errors, 0 warnings)

**Use Cases**:
- `/verify-emacs` command: emacs-verifier with iteration
- Refactoring: code-reviewer → fix → re-review loop

---

### Pattern 4: External Model Collaboration (Codex + Gemini)

**When to Use**: Leverage strengths of different AI models

**Example**: API development (from `/multi-api` command)

```bash
# Launch Codex (backend logic) and Gemini (developer experience) in parallel
codex_analysis=$(codex-wrapper "Analyze API backend architecture...")
gemini_analysis=$(gemini-wrapper "Analyze API developer experience...")

# Synthesize perspectives
# Codex authority: backend logic, security, performance
# Gemini authority: API design, documentation, usability
```

**Benefits**:
- 🎯 Specialized expertise (each model's strength)
- 🔀 Cross-validation (identify conflicts early)
- 📊 Balanced design (backend + frontend perspectives)

**Use Cases**:
- `/multi-api`: Codex + Gemini for API development
- Complex architecture: Multiple models for different layers

---

## Decision Tree: Which Pattern to Use?

```
START
  ↓
Are agents analyzing INDEPENDENT aspects?
  ├─ YES → Use Pattern 1 (Parallel Analysis)
  └─ NO
      ↓
    Does second agent DEPEND on first agent's output?
      ├─ YES → Use Pattern 2 (Sequential Pipeline)
      └─ NO
          ↓
        Does agent need to ITERATE until success?
          ├─ YES → Use Pattern 3 (Feedback Loop)
          └─ NO → Use Pattern 4 (External Model Collaboration)
```

---

## Automatic Launch Strategy

### Slash Command Triggers

**`/plan`** → Auto-launch `planner` + `code-reviewer` (Parallel)
**`/tdd`** → Auto-launch `planner` → (implement) → `code-reviewer` (Sequential)
**`/quality-gate`** → Auto-launch `code-reviewer`
**`/refactor-clean`** → Auto-launch `planner` + `code-reviewer` (Parallel)
**`/multi-*`** → Auto-launch multiple agents (Pattern from command definition)

### Post-Implementation Triggers

**After significant code changes:**
- 3+ files modified → Auto-launch `code-reviewer`
- 100+ lines changed → Auto-launch `code-reviewer`
- Before commit → Auto-launch `code-reviewer`

---

## Anti-Patterns (What NOT to Do)

### ❌ Anti-Pattern 1: Sequential When Parallel is Possible

**Bad**:
```javascript
// Unnecessarily slow: launch sequentially
Task({ subagent_type: "planner", ... })
// Wait for planner...
Task({ subagent_type: "code-reviewer", ... })
// Wait for reviewer...
// Total time: T1 + T2
```

**Good**:
```javascript
// Fast: launch simultaneously
Task({ subagent_type: "planner", ... })
Task({ subagent_type: "code-reviewer", ... })
// Total time: max(T1, T2)
```

---

### ❌ Anti-Pattern 2: Launching Agents for Simple Questions

**Bad**:
```javascript
User: "What does /plan command do?"
// Don't launch planner agent! Just explain the command.
Task({ subagent_type: "planner", ... }) // ❌ Wrong!
```

**Good**:
```javascript
User: "What does /plan command do?"
// Just answer directly
Response: "/plan creates a comprehensive implementation plan..."
```

---

### ❌ Anti-Pattern 3: Not Waiting for Dependencies

**Bad**:
```javascript
// Launch code-reviewer before planner finishes
Task({ subagent_type: "planner", ... })
Task({ subagent_type: "code-reviewer", ... }) // ❌ Reviewer needs planner output!
```

**Good**:
```javascript
// Wait for planner to complete first
Task({ subagent_type: "planner", ... })
// ... Wait for result ...
// Use planner output as input to code-reviewer
Task({ subagent_type: "code-reviewer", prompt: "Review based on plan: [planner output]..." })
```

---

### ❌ Anti-Pattern 4: No Synthesis of Agent Outputs

**Bad**:
```javascript
// Launch multiple agents but don't synthesize results
Task({ subagent_type: "planner", ... })
Task({ subagent_type: "code-reviewer", ... })
// Present both outputs as-is (user gets duplicate/conflicting info)
```

**Good**:
```javascript
// Launch agents
Task({ subagent_type: "planner", ... })
Task({ subagent_type: "code-reviewer", ... })
// Wait for both...
// Synthesize and resolve conflicts
// Present unified, comprehensive plan
```

---

## Success Metrics

**Multi-agent orchestration is working well when:**

✅ **Bug Reduction**: Fewer bugs make it to production (agents catch early)
✅ **Faster Workflows**: Parallel execution reduces total time
✅ **Comprehensive Coverage**: Multiple perspectives (architecture + security + quality)
✅ **Reduced Manual Oversight**: Automated reviews reduce human burden
✅ **Consistent Quality**: Every feature gets multi-agent review
✅ **Early Risk Detection**: Security/architecture issues caught in planning phase

**Metrics to Track**:
- Number of bugs caught by agents before implementation
- Time saved through parallel execution
- Code review coverage (% of changes reviewed by agents)
- User satisfaction (less back-and-forth, higher quality)

---

## Best Practices

### 1. Always Notify User

**Before launching agents**:
```markdown
**Auto-launching multi-agent analysis:**
- 🏗️ `planner` agent: Architectural planning
- 🔍 `code-reviewer` agent: Security pre-analysis

This will provide comprehensive analysis...
```

### 2. Synthesize Agent Outputs

Don't just present raw agent outputs. Instead:
- Identify common themes
- Resolve conflicts
- Prioritize recommendations
- Create unified, actionable plan

### 3. Track Agent Performance

Monitor:
- How many issues each agent catches
- How often agents disagree (indicates need for synthesis)
- User acceptance rate of agent recommendations

### 4. Iterate Based on Feedback

If agents consistently miss certain types of issues:
- Update agent instructions
- Add new specialized agents
- Refine orchestration patterns

---

## Example: `/plan` Command with Multi-Agent Orchestration

```javascript
// 1. Gather context
const context = await gatherContext(requirements)

// 2. Launch planner and code-reviewer in PARALLEL
const plannerTask = Task({
  subagent_type: "planner",
  description: "Architectural planning",
  prompt: `Analyze requirements and create implementation plan:
    Requirements: ${requirements}
    Context: ${context}

    Output: Step-by-step plan with file operations, dependencies, risks`
})

const reviewerTask = Task({
  subagent_type: "code-reviewer",
  description: "Security pre-analysis",
  prompt: `Review proposed changes for security and quality:
    Requirements: ${requirements}
    Context: ${context}

    Output: Security risks, quality concerns, best practices to follow`
})

// 3. Wait for BOTH agents to complete
const [plannerResult, reviewerResult] = await Promise.all([plannerTask, reviewerTask])

// 4. Synthesize results
const comprehensivePlan = synthesize({
  architecture: plannerResult.steps,
  security: reviewerResult.risks,
  bestPractices: reviewerResult.recommendations
})

// 5. Present unified plan to user
presentPlan(comprehensivePlan)
```

---

## Maintenance and Evolution

**When adding new agents**:
- [ ] Determine which slash commands should auto-launch this agent
- [ ] Identify orchestration pattern (parallel/sequential/feedback loop)
- [ ] Update `slash-command-automation.md`
- [ ] Add examples to this skill document

**When adding new slash commands**:
- [ ] Identify which agents to auto-launch
- [ ] Choose orchestration pattern
- [ ] Document in `slash-command-automation.md`
- [ ] Test multi-agent workflow end-to-end

**Quarterly Review**:
- Analyze which agents are most useful
- Identify gaps in coverage
- Refine orchestration patterns based on real-world usage
- Update documentation with new learnings
