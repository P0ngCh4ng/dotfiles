# Fix Bug - Root Cause Analysis and Strategic Bug Fixing

Fix bugs with root cause analysis, strategic fixing, and regression prevention.

$ARGUMENTS (bug description, issue number, or error message)

---

## Workflow

### Phase 1: Bug Analysis and Reproduction

1. **Gather Bug Information**
   - Parse $ARGUMENTS: bug description, issue number, or error
   - If issue number: fetch from GitHub/GitLab/Jira
   - Collect:
     - Error messages and stack traces
     - Steps to reproduce
     - Expected vs actual behavior
     - Environment (OS, browser, version)
     - User impact (severity, frequency)

2. **Reproduce the Bug**
   - Set up reproduction environment
   - Follow reproduction steps
   - Verify bug exists
   - Document exact conditions for bug to occur

3. **Initial Investigation**
   - Search codebase for relevant code: `Grep` for error messages, function names
   - Read related files: `Read` suspicious files
   - Check recent changes: `git log --grep="keyword"`
   - Review related issues: `gh issue list --search "keyword"`

### Phase 2: Multi-Agent Root Cause Analysis (Parallel Launch)

**Launch planner and code-reviewer in PARALLEL:**

#### Agent 1: Root Cause Analysis and Fix Strategy

```javascript
Task({
  subagent_type: "planner",
  description: "Bug root cause analysis",
  prompt: `Analyze bug and identify root cause with strategic fix plan.

Bug: ${bug_description}
Error: ${error_message}
Stack trace: ${stack_trace}
Reproduction steps: ${steps}
Related code: ${code_context}

Perform:
1. Root Cause Analysis
   - What is the immediate cause?
   - What is the underlying cause?
   - Why did this bug occur (design flaw, edge case, etc.)?
   - Was this preventable (by tests, validation, etc.)?

2. Impact Assessment
   - What systems/features are affected?
   - What data could be corrupted?
   - What security implications?
   - How many users impacted?

3. Fix Strategy (multiple approaches)
   - Approach A: [description]
     - Pros: ${pros}
     - Cons: ${cons}
     - Risk: ${risk_level}
   - Approach B: [description]
     - ...

4. Recommended Approach
   - Why this approach is best
   - Implementation steps
   - Expected side effects
   - Testing strategy

5. Regression Prevention
   - What tests should be added?
   - What validation should be added?
   - What monitoring should be added?

Output: Comprehensive root cause analysis with recommended fix strategy`
})
```

#### Agent 2: Security and Quality Impact Analysis

```javascript
Task({
  subagent_type: "code-reviewer",
  description: "Bug fix security and quality review",
  prompt: `Analyze bug for security implications and quality considerations.

Bug: ${bug_description}
Error: ${error_message}
Affected code: ${code_context}

Analyze:
1. Security Implications
   - Is this a security vulnerability?
   - Could it be exploited?
   - What data is at risk?
   - Should this be disclosed responsibly?

2. Data Integrity
   - Could data be corrupted?
   - Do we need data migration?
   - Should we validate existing data?

3. Fix Constraints
   - What must not break (backward compatibility)?
   - What tests must pass?
   - What edge cases to consider?

4. Quality Impact
   - Code areas that need refactoring
   - Technical debt to address
   - Best practices to apply

5. Blast Radius
   - What could go wrong with the fix?
   - What areas need extra testing?
   - What monitoring should be added?

Output: Security risks, data integrity concerns, fix constraints, quality considerations`
})
```

**Both agents run in PARALLEL** for comprehensive analysis

### Phase 3: Synthesize Fix Strategy

1. **Combine Agent Insights**
   - Planner's root cause analysis + fix strategies
   - Code-reviewer's security/quality constraints
   - Resolve conflicts and prioritize approach

2. **Comprehensive Bug Fix Plan**
   ```markdown
   ## Bug Fix Plan: ${bug_title}

   ### Bug Summary
   - **Description:** ${description}
   - **Severity:** ${severity} (Critical/High/Medium/Low)
   - **Impact:** ${user_impact}
   - **Frequency:** ${frequency}

   ### Root Cause Analysis
   **Immediate Cause:**
   ${immediate_cause}

   **Underlying Cause:**
   ${underlying_cause}

   **Why It Occurred:**
   ${why_occurred}

   **Preventability:**
   ${how_to_prevent}

   ### Security & Data Impact
   - **Security risk:** ${security_risk}
   - **Data integrity:** ${data_integrity}
   - **Requires migration:** ${needs_migration}

   ### Fix Strategy (Recommended: Approach ${recommended})

   #### Approach ${recommended}
   - **Description:** ${description}
   - **Pros:** ${pros}
   - **Cons:** ${cons}
   - **Risk:** ${risk}

   #### Implementation Steps
   1. ${step_1}
   2. ${step_2}
   3. ...

   #### Files to Modify
   | File | Change | Reason |
   |------|--------|--------|
   | ${file_1} | ${change_1} | ${reason_1} |

   #### Testing Strategy
   - Unit tests: ${unit_tests}
   - Integration tests: ${integration_tests}
   - Manual testing: ${manual_steps}
   - Edge cases: ${edge_cases}

   ### Regression Prevention
   - **Tests to add:** ${tests}
   - **Validation to add:** ${validation}
   - **Monitoring to add:** ${monitoring}

   ### Rollback Plan
   - If fix causes issues: ${rollback_steps}
   - Feature flag: ${feature_flag_needed}

   ### Expected Side Effects
   - ${side_effect_1}
   - ${side_effect_2}
   ```

### Phase 4: User Confirmation

**Present plan and wait for approval:**

```markdown
## Bug Fix Plan Ready

**Multi-agent analysis complete:**
- 🔍 planner: Root cause identified - ${root_cause}
- 🔒 code-reviewer: ${security_findings}

**Recommended Fix:** ${fix_approach}

**Impact:**
- Severity: ${severity}
- Users affected: ${user_count}
- Security risk: ${security_level}

**Implementation:**
- Estimated time: ${time_estimate}
- Risk level: ${risk_level}
- Tests required: ${test_count}

**Next Steps:**
- ✅ Approve: Proceed with fix implementation
- 📝 Modify: Adjust fix strategy
- 🔬 Investigate: Need more analysis

Would you like me to proceed with the fix?
```

### Phase 5: Implementation (After Approval)

1. **Implement Fix**
   - Follow implementation steps from plan
   - Make minimal changes (avoid scope creep)
   - Add inline comments explaining fix
   - Follow coding standards

2. **Add Regression Tests**
   - Write test that reproduces bug (should fail before fix)
   - Verify test passes after fix
   - Add edge case tests
   - Verify related tests still pass

3. **Verify Fix**
   - Reproduce bug again (should not occur)
   - Test edge cases
   - Test related functionality (no regressions)
   - Verify performance (no degradation)

### Phase 6: Post-Fix Review

**Auto-launch code-reviewer for final check:**

```javascript
Task({
  subagent_type: "code-reviewer",
  description: "Post-fix review",
  prompt: `Review bug fix implementation for quality and completeness.

Bug: ${bug_description}
Fix implemented: ${fix_code}
Tests added: ${test_code}

Verify:
- Fix addresses root cause (not just symptom)
- No new security vulnerabilities introduced
- Tests are comprehensive (bug + edge cases)
- No regressions in related code
- Code quality maintained
- Error handling proper
- Comments explain fix rationale

Provide:
- Issues found (if any)
- Suggestions for improvement
- Approval status`
})
```

### Phase 7: Documentation and Commit

1. **Document Fix**
   - Update CHANGELOG (if user-facing bug)
   - Add comment in code explaining fix
   - Update issue tracker
   - Link commit to issue

2. **Commit with Descriptive Message**
   ```bash
   git add .
   git commit -m "fix: ${bug_title}

   Root cause: ${root_cause}

   Fix: ${fix_description}

   - Added test: ${test_description}
   - Verified no regressions
   - Closes #${issue_number}

   🤖 Generated with [Claude Code](https://claude.com/claude-code)

   Co-Authored-By: Claude <noreply@anthropic.com>"
   ```

3. **Report Results**
   ```markdown
   ## Bug Fix Complete

   **Bug:** ${bug_title}
   **Root Cause:** ${root_cause}
   **Fix Applied:** ${fix_summary}

   **Tests Added:**
   - ${test_1}
   - ${test_2}

   **Verification:**
   - ✅ Bug no longer reproducible
   - ✅ All tests pass
   - ✅ No regressions detected
   - ✅ Code reviewed by agent

   **Next Steps:**
   - Monitor in production
   - Close issue #${issue_number}
   - Consider backporting to previous versions
   ```

---

## Bug Severity Levels

### Critical 🚨
- Production down / major functionality broken
- Data loss or corruption
- Security vulnerability actively exploited
- **Action:** Immediate hotfix

### High ⚠️
- Major feature broken but workaround exists
- Affects many users
- Security vulnerability not yet exploited
- **Action:** Fix in next release (days)

### Medium 📋
- Minor feature broken
- Affects some users
- Poor user experience
- **Action:** Fix in upcoming sprint (weeks)

### Low 💡
- Edge case issue
- Cosmetic problem
- Rare occurrence
- **Action:** Fix when convenient (months)

---

## Root Cause Analysis Framework

### 5 Whys Technique
```
Bug: User login fails
Why? → Session token expired
Why? → Token TTL too short
Why? → Default config not updated
Why? → No validation of config values
Why? → Configuration management process lacking
Root cause: Need better config management
```

### Categories of Root Causes
1. **Logic Error** - Incorrect algorithm, off-by-one, wrong condition
2. **Edge Case** - Unhandled boundary condition, null/empty/zero
3. **Race Condition** - Concurrency issue, timing problem
4. **Data Issue** - Invalid data, corrupt state, wrong assumptions
5. **Integration Issue** - API change, dependency problem, config mismatch
6. **Design Flaw** - Architectural problem, wrong abstraction

---

## Regression Prevention

### Add Tests
- **Reproduction test:** Test that fails before fix, passes after
- **Edge case tests:** Cover boundary conditions
- **Integration tests:** Verify fix works in context

### Add Validation
- Input validation at boundaries
- Assertion checks in critical paths
- Type checks (if dynamic language)

### Add Monitoring
- Log key events
- Add metrics/counters
- Set up alerts for anomalies

---

## Auto-Launch Conditions

This command automatically triggers when:
- User requests: "Fix bug [description]"
- User provides: "Error: [error message]"
- User mentions: "バグ修正", "エラー対応"
- Keywords: "fix", "bug", "error", "broken"

---

## Success Criteria

✅ Bug reproduced and understood
✅ Root cause identified (not just symptom)
✅ Multiple fix approaches considered
✅ Security and quality implications analyzed
✅ Fix implemented with minimal changes
✅ Regression tests added
✅ Bug no longer reproducible
✅ Code reviewed (no new issues introduced)
✅ Documented and committed

---

## Notes

- **Root cause, not symptom:** Fix underlying cause, not just visible error
- **Multi-agent analysis:** planner (root cause) + code-reviewer (security/quality)
- **Test-driven:** Write test first, verify it fails, then fix
- **Minimal fix:** Don't refactor unrelated code (scope creep)
- **Regression prevention:** Always add tests to prevent recurrence
