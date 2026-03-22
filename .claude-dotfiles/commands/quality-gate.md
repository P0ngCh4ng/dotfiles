# Quality Gate - Comprehensive Quality Assurance with Multi-Agent Analysis

Run comprehensive quality pipeline with multi-agent analysis covering code quality, security, documentation, and test coverage.

$ARGUMENTS (path or "." for current directory, optional: --fix, --strict)

---

## Usage

`/quality-gate [path|.] [--fix] [--strict]`

- **default target:** current directory (`.`)
- **--fix:** allow auto-format/fix where configured
- **--strict:** fail on warnings where supported

---

## Workflow

### Phase 1: Environment Detection and Baseline

1. **Detect Language and Tooling**
   - Parse target path from $ARGUMENTS
   - Detect language(s): JavaScript/TypeScript, Python, Go, Rust, Ruby, etc.
   - Identify available tools:
     - **Formatters:** Prettier, Black, rustfmt, gofmt
     - **Linters:** ESLint, Pylint, golangci-lint, Clippy, RuboCop
     - **Type Checkers:** TypeScript, mypy, Flow
     - **Test Runners:** Jest, pytest, Go test, cargo test
     - **Coverage Tools:** Jest --coverage, pytest-cov, go test -cover

2. **Establish Baseline**
   - Run all tests: `npm test` | `pytest` | `go test ./...` | `cargo test`
   - Measure test coverage
   - Count existing linter warnings/errors
   - Record formatting issues

### Phase 2: Multi-Agent Quality Analysis (Parallel Launch)

**Launch code-reviewer and doc-updater in PARALLEL:**

#### Agent 1: Code Quality and Security Review

```javascript
Task({
  subagent_type: "code-reviewer",
  description: "Quality gate code review",
  prompt: `Perform comprehensive code quality and security review for quality gate.

Target: ${target_path}
Language: ${detected_language}
Context: ${code_context}

Analyze:
1. **Security Vulnerabilities**
   - Injection vulnerabilities (SQL, XSS, command injection)
   - Authentication/authorization issues
   - Sensitive data exposure
   - Dependency vulnerabilities (npm audit, pip-audit, cargo audit)

2. **Code Quality**
   - Code duplication (DRY violations)
   - Excessive complexity (cyclomatic complexity)
   - Code smells (long functions, large classes)
   - Anti-patterns

3. **Best Practices**
   - Error handling completeness
   - Input validation at boundaries
   - Proper logging and monitoring
   - Resource cleanup (memory leaks, file handles)

4. **Test Quality**
   - Test coverage (line and branch)
   - Missing test cases (edge cases, error scenarios)
   - Test reliability (flaky tests)

5. **Maintainability**
   - Code readability
   - Naming conventions
   - Comment quality
   - Module structure

Provide:
- Critical issues (blockers for deployment)
- High priority issues (should fix before merge)
- Medium priority issues (technical debt)
- Low priority issues (nice-to-have improvements)
- Overall quality score (0-100)`
})
```

#### Agent 2: Documentation Quality Review

```javascript
Task({
  subagent_type: "doc-updater",
  description: "Quality gate documentation review",
  prompt: `Review documentation quality as part of quality gate.

Target: ${target_path}
Documentation: ${docs_found}
Code changes: ${recent_changes}

Check:
1. **Documentation Completeness**
   - README up to date
   - API documentation complete
   - Code comments for complex logic
   - Examples working and relevant

2. **Documentation Quality**
   - Clear and understandable
   - Accurate (matches code)
   - Well-formatted
   - No broken links

3. **Documentation Gaps**
   - New features undocumented
   - Breaking changes not noted
   - Missing migration guides
   - Insufficient examples

Provide:
- Missing documentation
- Outdated documentation
- Documentation quality issues
- Suggested improvements`
})
```

**Both agents run in PARALLEL** for comprehensive quality assessment

### Phase 3: Automated Quality Checks

**Run standard quality tools:**

1. **Formatter Check**
   ```bash
   # JavaScript/TypeScript
   npx prettier --check .

   # Python
   black --check .

   # Go
   gofmt -l .

   # Rust
   cargo fmt --check
   ```

2. **Linter Check**
   ```bash
   # JavaScript/TypeScript
   npx eslint . [--fix]

   # Python
   pylint src/ [--fix]

   # Go
   golangci-lint run [--fix]

   # Rust
   cargo clippy [--fix]
   ```

3. **Type Check**
   ```bash
   # TypeScript
   npx tsc --noEmit

   # Python
   mypy src/
   ```

4. **Security Audit**
   ```bash
   # JavaScript
   npm audit [--fix]

   # Python
   pip-audit

   # Rust
   cargo audit
   ```

5. **Test Execution**
   ```bash
   # Run all tests with coverage
   npm test -- --coverage
   pytest --cov
   go test -cover ./...
   cargo test
   ```

### Phase 4: Synthesize Quality Report

**Combine all findings:**

```markdown
## Quality Gate Report: ${target_path}

### Executive Summary
- **Overall Status:** ${pass_fail}
- **Quality Score:** ${score}/100
- **Critical Issues:** ${critical_count}
- **Test Coverage:** ${coverage_percentage}%

### Automated Checks
| Check | Status | Issues |
|-------|--------|--------|
| Formatting | ${format_status} | ${format_issues} |
| Linting | ${lint_status} | ${lint_issues} |
| Type Checking | ${type_status} | ${type_issues} |
| Security Audit | ${security_status} | ${security_issues} |
| Tests | ${test_status} | ${test_failures} |
| Coverage | ${coverage_status} | ${coverage_percentage}% |

### Code Quality Review (code-reviewer)
#### Critical Issues 🚨 (${critical_count})
- [File:Line] ${issue_description}
- Suggested fix: ${fix}

#### High Priority ⚠️ (${high_count})
- ...

#### Medium Priority 📋 (${medium_count})
- ...

#### Low Priority 💡 (${low_count})
- ...

### Documentation Quality (doc-updater)
#### Missing Documentation
- ${missing_doc_1}
- ${missing_doc_2}

#### Outdated Documentation
- ${outdated_doc_1}

### Test Coverage Analysis
- **Line Coverage:** ${line_coverage}% (target: 80%)
- **Branch Coverage:** ${branch_coverage}% (target: 80%)
- **Uncovered Files:** ${uncovered_files}
- **Missing Test Cases:** ${missing_tests}

### Quality Gate Decision
${decision_explanation}

**Recommendation:**
- ✅ **PASS:** Ready for deployment
- ⚠️ **PASS WITH WARNINGS:** Deploy but address issues soon
- 🚫 **FAIL:** Must fix critical issues before deployment
```

### Phase 5: Interactive Remediation

**If --fix flag provided:**
1. Auto-apply safe fixes (formatting, simple linter fixes)
2. Present manual fixes for review
3. Re-run quality checks to verify fixes

**Present results to user:**
```markdown
## Quality Gate: ${status}

**Multi-agent analysis:**
- 🔍 code-reviewer: ${issue_count} issues found
- 📖 doc-updater: ${doc_issue_count} documentation issues

**Automated checks:**
- Format: ${format_status}
- Lint: ${lint_status}
- Tests: ${test_status}
- Coverage: ${coverage_percentage}%

**Decision:** ${pass_fail}

${decision_reasoning}

**Next Steps:**
${next_steps}
```

---

## Quality Gate Criteria

### PASS ✅
- No critical security issues
- No failing tests
- 80%+ test coverage (line and branch)
- No high-severity linter errors
- Formatting compliant
- No critical documentation gaps

### PASS WITH WARNINGS ⚠️
- No critical issues
- Some medium/low priority issues
- 60-79% test coverage
- Documentation could be improved

### FAIL 🚫
- Critical security vulnerabilities
- Failing tests
- < 60% test coverage
- High-severity bugs
- Missing critical documentation

---

## Auto-Launch Conditions

This command automatically triggers when:
- Before deployment/merge
- User requests: "Quality check"
- User requests: "Run quality gate"
- Keywords: "品質チェック", "QAゲート"

---

## Integration with CI/CD

**This command can be used in CI/CD:**
```yaml
# GitHub Actions example
- name: Quality Gate
  run: claude code /quality-gate . --strict
```

**Exit codes:**
- `0` - PASS
- `1` - PASS WITH WARNINGS (can configure to fail on warnings with --strict)
- `2` - FAIL

---

## Success Criteria

✅ Language and tools detected
✅ Baseline established (tests pass)
✅ Multi-agent analysis complete (code-reviewer + doc-updater)
✅ Automated checks executed
✅ Quality report generated
✅ Clear pass/fail decision
✅ Actionable remediation list provided

---

## Notes

- **Comprehensive:** Covers code, security, tests, docs, dependencies
- **Multi-agent:** code-reviewer (quality/security) + doc-updater (documentation)
- **Automated:** Standard tools + agent analysis
- **Actionable:** Specific fixes with file:line references
- **Strict mode:** Fail on warnings (--strict flag)
