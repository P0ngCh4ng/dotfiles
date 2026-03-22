# Plan - Comprehensive Feature Planning with Multi-Agent Review

Restate requirements, assess risks, and create a step-by-step implementation plan. WAIT for user CONFIRM before touching any code.

$ARGUMENTS

---

## Workflow

### Phase 1: Requirements Analysis

1. **Restate Requirements**
   - Parse user's request: $ARGUMENTS
   - Clarify scope, constraints, acceptance criteria
   - Identify ambiguities and ask clarifying questions if needed

2. **Context Gathering**
   - Read relevant files (use Glob, Grep, Read tools)
   - Understand existing architecture and patterns
   - Identify related code that may be affected
   - Check for existing tests and documentation

3. **Requirement Validation**
   - Verify requirements are complete and unambiguous
   - Identify edge cases and potential issues
   - Confirm understanding with user if unclear

### Phase 2: Multi-Agent Analysis

**CRITICAL**: Launch the following agents in **PARALLEL** for comprehensive review:

1. **`planner` agent** - Architectural planning and implementation steps
   - Break down requirements into concrete steps
   - Identify file changes and dependencies
   - Assess architectural impacts
   - Suggest optimal implementation approach

2. **`code-reviewer` agent** - Quality and security pre-analysis
   - Review proposed changes for security implications
   - Check for potential code quality issues
   - Identify best practices to follow
   - Flag potential risks

**Launch both agents simultaneously using Task tool:**

```
Task({
  subagent_type: "planner",
  description: "Architectural planning",
  prompt: "Analyze requirements and create detailed implementation plan: $ARGUMENTS\n\nContext: [gathered context]"
})

Task({
  subagent_type: "code-reviewer",
  description: "Security and quality analysis",
  prompt: "Review proposed changes for security, quality, and best practices: $ARGUMENTS\n\nContext: [gathered context]"
})
```

3. **Synthesize Agent Feedback**
   - Combine insights from both agents
   - Resolve any conflicts or inconsistencies
   - Create unified, comprehensive plan

### Phase 3: Risk Assessment

Identify and document:
- **Technical Risks**: Breaking changes, performance impacts, compatibility issues
- **Implementation Risks**: Complexity, dependencies, testing challenges
- **Security Risks**: Authentication, authorization, data validation, injection vulnerabilities
- **Mitigation Strategies**: For each identified risk

### Phase 4: Implementation Plan

Generate step-by-step plan with:

1. **File Operations**
   | File Path | Operation | Description |
   |-----------|-----------|-------------|
   | path/to/file | Create/Modify/Delete | Brief description |

2. **Implementation Steps**
   - Step 1: [Detailed description with code snippets if needed]
   - Step 2: [...]
   - Step N: [...]

3. **Testing Strategy**
   - Unit tests to write
   - Integration tests to add
   - Manual testing steps
   - Coverage targets

4. **Documentation Updates**
   - README updates
   - API documentation
   - Code comments
   - Migration guides (if breaking changes)

5. **Dependencies and Order**
   - Sequential dependencies
   - What can be done in parallel
   - Critical path items

### Phase 5: Plan Delivery

**Save plan to `.claude/plans/<feature-name>.md`**

**Present plan to user with:**
- Executive summary
- Key decisions and trade-offs
- Risk assessment
- Estimated complexity/effort
- Next steps

**WAIT for user confirmation before proceeding**

Output:
```
## Plan Ready: <feature-name>

[Executive Summary]

**Key Decisions:**
- Decision 1
- Decision 2

**Risks and Mitigations:**
- Risk 1 → Mitigation 1
- Risk 2 → Mitigation 2

**Implementation Steps:**
1. Step 1
2. Step 2
...

**Saved to:** `.claude/plans/<feature-name>.md`

---

**Please review the plan above. You can:**
- ✅ **Approve**: Tell me to proceed with implementation
- 📝 **Modify**: Request changes to the plan
- ❌ **Reject**: Discuss alternative approaches
```

---

## Rules

1. **Planning Only** - This command does NOT implement code, only creates plans
2. **No Y/N Prompts** - Present plan and wait for user decision
3. **Multi-Agent Required** - MUST launch planner + code-reviewer in parallel
4. **Save Before Present** - Always save plan file before showing to user
5. **Risk Assessment Mandatory** - Every plan must include risk analysis
6. **Wait for Confirm** - Never auto-proceed to implementation

---

## Auto-Launch Conditions

This command automatically launches when user requests:
- "Plan for [feature]"
- "Design [feature]"
- "How should I implement [feature]"
- "Architecture for [feature]"
- Keywords: "計画", "プラン", "設計"

---

## Next Steps After Approval

When user approves the plan:
1. Implement according to plan steps
2. Auto-launch `code-reviewer` after each significant code change
3. Run tests after implementation
4. Update documentation
5. Commit with descriptive message
