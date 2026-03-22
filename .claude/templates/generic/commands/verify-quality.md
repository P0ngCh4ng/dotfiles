Your task is to perform a comprehensive code quality verification on the current changes in this repository.

## Instructions

1. **Identify Changed Files**
   - Run `git status` to see modified/added files
   - Run `git diff` to see actual changes
   - Focus on source code files (ignore generated files, lock files, etc.)

2. **Invoke Quality Enforcer Agent**
   - Use the code-quality-enforcer agent to analyze the changes
   - The agent should check all quality standards defined in the agent file
   - Get a comprehensive report of issues and recommendations

3. **Run Automated Checks (if available)**
   - Linting: Run project linter if configured
   - Tests: Run test suite and check coverage
   - Type checking: Run type checker if applicable
   - Build: Verify project builds successfully

4. **Generate Summary Report**
   - Summarize findings from quality enforcer
   - Include results from automated tools
   - Categorize issues by priority (critical, high, medium, low)
   - Provide specific file and line references
   - Estimate effort to fix each issue

5. **Provide Recommendations**
   - For each issue, suggest specific fix
   - Show code examples where helpful
   - Prioritize what should be fixed before commit
   - Note what can be addressed in follow-up

## Report Format

Present findings in this format:

```markdown
# Code Quality Verification Report

Generated: [timestamp]
Branch: [branch name]
Files Changed: [count]

## Executive Summary
- Overall Status: ✅ PASS / ⚠️  PASS WITH WARNINGS / ❌ FAIL
- Critical Issues: [count]
- High Priority: [count]
- Medium Priority: [count]
- Low Priority: [count]

## Quick Stats
- Test Coverage: [percentage]
- Files Analyzed: [count]
- Lines Changed: [+additions / -deletions]

---

## Critical Issues (Block Commit)

### 1. [Issue Title]
**File**: path/to/file.ext:line
**Category**: Security / Tests / Documentation / etc.
**Description**: [What's wrong]
**Impact**: [Why this matters]
**Fix**: [How to resolve]
**Effort**: Quick / Medium / Significant

---

## High Priority Issues (Fix Before Merge)

[Same format as critical]

---

## Medium Priority Issues (Address Soon)

[Same format as critical]

---

## Low Priority Issues (Nice to Fix)

[Same format as critical]

---

## Automated Tool Results

### Linter
[Results from linter]

### Tests
[Test results]
- Total: [count]
- Passed: [count]
- Failed: [count]
- Coverage: [percentage]

### Build
[Build status]

---

## Recommendations

1. **Immediate Actions** (before commit):
   - [Action 1]
   - [Action 2]

2. **Before Merge**:
   - [Action 1]
   - [Action 2]

3. **Follow-up**:
   - [Action 1]
   - [Action 2]

---

## Detailed Findings

[Include full output from code-quality-enforcer agent]

---

## Files Reviewed

- ✅ path/to/file1.ext - No issues
- ⚠️  path/to/file2.ext - 2 warnings
- ❌ path/to/file3.ext - 1 critical issue

---

## Next Steps

1. [ ] Fix all critical issues
2. [ ] Address high priority items
3. [ ] Run `/verify-quality` again
4. [ ] Request code review
5. [ ] Merge after approval
```

## Notes

- Focus on constructive feedback
- Be specific with file paths and line numbers
- Provide code examples for suggested fixes
- Consider project context (MVP vs production-ready)
- Highlight what's done well, not just problems
- Make the report actionable and clear

## Example Usage Context

This command should be run:
- Before committing changes
- Before pushing to remote
- Before requesting code review
- After addressing review comments
- As part of CI/CD pipeline

## Success Criteria

Quality verification passes when:
- Zero critical issues
- Test coverage meets threshold
- All automated checks pass
- Code follows project standards
- Documentation is complete
- No security vulnerabilities

## Failure Criteria

Quality verification fails when:
- Any critical issues present
- Test coverage below minimum
- Build fails
- Security vulnerabilities detected
- Required documentation missing
