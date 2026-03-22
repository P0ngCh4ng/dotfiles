# Review PR - Comprehensive Pull Request Review with Multi-Agent Analysis

Conduct comprehensive pull request review with multi-agent analysis covering code quality, security, documentation, and design (if UI changes).

$ARGUMENTS (PR number, URL, or branch name)

---

## Workflow

### Phase 1: PR Context Gathering

1. **Identify PR**
   - Parse $ARGUMENTS: PR number, URL, or branch name
   - Fetch PR details using `gh pr view <number>`
   - Get changed files: `gh pr diff <number>`
   - Get PR description and commits

2. **Analyze Changes**
   - List all changed files: `gh pr diff <number> --name-only`
   - Count lines changed: `git diff main...HEAD --stat`
   - Identify file types (code, tests, docs, config, UI)
   - Detect breaking changes (from commit messages, CHANGELOG)

3. **Categorize Changes**
   - **Code changes**: `*.{js,ts,py,go,rb,java,etc}`
   - **Test changes**: `*.{test,spec}.{js,ts,py,go,rb}`
   - **Documentation changes**: `*.md`, `docs/**/*`
   - **UI changes**: `*.{vue,jsx,tsx,css,scss,html}`
   - **Configuration changes**: `*.{json,yaml,yml,toml,env}`

### Phase 2: Multi-Agent Review (Parallel Launch)

**Launch agents based on change types:**

#### Always Launch: Code Quality & Security Review

```javascript
Task({
  subagent_type: "code-reviewer",
  description: "PR code quality and security review",
  prompt: `Review pull request for code quality, security, and best practices.

PR: ${pr_number}
Changed files: ${changed_files}
Diff: ${diff_content}

Check for:
- Security vulnerabilities (injection, XSS, auth issues)
- Code quality issues (duplication, complexity, maintainability)
- Best practices violations
- Error handling completeness
- Input validation
- Breaking changes
- Performance concerns
- Test coverage adequacy

Provide:
- List of issues (Critical, High, Medium, Low priority)
- Specific file:line references
- Suggested fixes
- Approval status (Approve, Request Changes, Comment)`
})
```

#### Conditional Launch 1: Documentation Review (if docs changed)

```javascript
if (has_doc_changes || has_breaking_changes) {
  Task({
    subagent_type: "doc-updater",
    description: "PR documentation review",
    prompt: `Review pull request documentation completeness and quality.

PR: ${pr_number}
Changed files: ${changed_files}

Check for:
- README updates (if API/features changed)
- CHANGELOG updates (if user-facing changes)
- API documentation (if endpoints/functions changed)
- Migration guide (if breaking changes)
- Code comments (for complex logic)
- Examples and usage (if new features)

Provide:
- Missing documentation
- Documentation quality issues
- Suggested additions`
  })
}
```

#### Conditional Launch 2: Design Review (if UI changed)

```javascript
if (has_ui_changes && design_review_enabled) {
  Task({
    subagent_type: "design-review",
    description: "PR design and UI review",
    prompt: `Review pull request UI changes for design consistency and quality.

PR: ${pr_number}
UI files changed: ${ui_files}

Check for:
- Visual consistency (colors, typography, spacing)
- Responsive design (mobile, tablet, desktop)
- Accessibility (WCAG 2.1 compliance)
- Component consistency
- Layout quality

Provide:
- Design issues found
- Accessibility violations
- Suggestions for improvement`
  })
}
```

**All agents run in PARALLEL** (fastest completion)

### Phase 3: Synthesize Review Results

1. **Aggregate Agent Findings**
   - Combine findings from all agents
   - Remove duplicates
   - Prioritize issues (Critical → High → Medium → Low)

2. **Generate Comprehensive Review**
   ```markdown
   ## PR Review: #${pr_number} - ${pr_title}

   ### Overview
   - Files changed: ${file_count}
   - Lines added: ${lines_added}
   - Lines removed: ${lines_removed}
   - Breaking changes: ${has_breaking_changes ? 'Yes' : 'No'}

   ### Code Quality & Security (code-reviewer)
   #### Critical Issues (${critical_count})
   - [File:Line] Issue description
   - Suggested fix

   #### High Priority (${high_count})
   - ...

   #### Medium Priority (${medium_count})
   - ...

   ### Documentation (doc-updater)
   #### Missing Documentation
   - README update needed
   - CHANGELOG entry required

   #### Quality Issues
   - ...

   ### Design & UI (design-review)
   #### Accessibility Issues
   - WCAG violations found

   #### Design Consistency
   - ...

   ### Overall Assessment
   - ✅ Approve | ⚠️ Request Changes | 💬 Comment
   - Summary and recommendations
   ```

3. **Post Review Comment**
   - Use `gh pr review <number>` to post review
   - Include all findings in structured format
   - Set review status (APPROVE, REQUEST_CHANGES, COMMENT)

### Phase 4: Interactive Feedback

**Present review to user:**
```markdown
## PR Review Complete: #${pr_number}

**Multi-agent analysis:**
- ✅ code-reviewer: ${issue_count} issues found
- ✅ doc-updater: ${doc_issue_count} documentation issues
- ✅ design-review: ${design_issue_count} design issues (if applicable)

**Overall Status:** ${status}

**Next steps:**
1. Post review to GitHub (command ready)
2. Request changes from author
3. Approve if all issues resolved

Would you like me to post this review to GitHub?
```

---

## Review Criteria

### Code Quality Checklist
- [ ] No security vulnerabilities
- [ ] Proper error handling
- [ ] Input validation at boundaries
- [ ] No code duplication
- [ ] Maintainable complexity
- [ ] Follows project conventions
- [ ] Tests cover changes
- [ ] No breaking changes (or documented)

### Documentation Checklist
- [ ] README updated (if needed)
- [ ] CHANGELOG updated (if user-facing)
- [ ] API docs updated (if API changed)
- [ ] Migration guide (if breaking changes)
- [ ] Code comments for complex logic

### Design Checklist (if UI)
- [ ] Visual consistency maintained
- [ ] Responsive design works
- [ ] Accessibility compliant
- [ ] Performance acceptable
- [ ] Cross-browser compatible

---

## Auto-Launch Conditions

This command automatically triggers when:
- User requests: "Review PR #123"
- User requests: "Review this pull request"
- User provides GitHub PR URL
- Keywords: "PRレビュー", "プルリクエスト確認"

---

## Priority Levels

**Critical** 🚨
- Security vulnerabilities
- Data loss risks
- Production-breaking bugs
- **Action:** Must fix before merge

**High** ⚠️
- Logic errors
- Performance issues
- Missing error handling
- **Action:** Should fix before merge

**Medium** 📋
- Code quality issues
- Minor design inconsistencies
- Documentation gaps
- **Action:** Fix or create follow-up issue

**Low** 💡
- Style suggestions
- Optimization opportunities
- Nice-to-have improvements
- **Action:** Optional, consider for future

---

## Integration with GitHub CLI

**Required tool:** `gh` (GitHub CLI)

**Common commands:**
```bash
# View PR
gh pr view <number>

# Get PR diff
gh pr diff <number>

# Post review
gh pr review <number> --approve --body "Review comment"
gh pr review <number> --request-changes --body "Issues found"
gh pr review <number> --comment --body "General feedback"

# Check PR status
gh pr checks <number>
```

---

## Example Usage

```bash
# Review by PR number
/review-pr 123

# Review by URL
/review-pr https://github.com/user/repo/pull/123

# Review current branch
/review-pr
```

---

## Output Format

**Structured review with:**
1. **Executive Summary**
   - Overall status (Approve/Request Changes/Comment)
   - Key findings
   - Statistics (files, lines, issues)

2. **Detailed Findings**
   - Grouped by priority (Critical → Low)
   - File:line references
   - Suggested fixes

3. **Agent Reports**
   - code-reviewer findings
   - doc-updater findings
   - design-review findings (if applicable)

4. **Action Items**
   - Must-fix before merge
   - Should-fix before merge
   - Follow-up issues to create

---

## Success Criteria

✅ All agents complete review
✅ Findings prioritized and categorized
✅ Specific file:line references provided
✅ Actionable suggestions given
✅ Review posted to GitHub (if user approves)
✅ Clear approval/request changes status

---

## Notes

- **Parallel execution:** All agents run simultaneously for speed
- **Conditional agents:** Design review only if UI changes detected
- **Interactive:** User confirms before posting review to GitHub
- **Comprehensive:** Covers code, docs, design, security, quality
