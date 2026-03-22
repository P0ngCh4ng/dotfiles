# Refactor Clean - Strategic Refactoring with Multi-Agent Analysis

Safely identify and remove dead code, reduce complexity, and improve code quality with multi-agent strategic planning and test verification at every step.

$ARGUMENTS (target: file, directory, or feature to refactor)

---

## Workflow

### Phase 1: Multi-Agent Strategic Analysis (Parallel Launch)

**Before identifying dead code, launch planner and code-reviewer in PARALLEL:**

#### Agent 1: Refactoring Strategy and Prioritization

```javascript
Task({
  subagent_type: "planner",
  description: "Refactoring strategy planning",
  prompt: `Analyze codebase and create strategic refactoring plan.

Target: ${target_path}
Context: ${code_context}

Analyze:
1. **Code Quality Issues**
   - Dead code (unused exports, functions, files)
   - Code duplication (DRY violations)
   - Excessive complexity (high cyclomatic complexity)
   - Large functions/classes (should be split)
   - Poor abstractions

2. **Technical Debt**
   - Anti-patterns
   - Code smells
   - Outdated patterns
   - Missing abstractions

3. **Refactoring Opportunities** (prioritized by impact/risk)
   - Safe refactorings (low risk, high value)
   - Medium risk refactorings (require careful testing)
   - High risk refactorings (may need feature flags)

4. **Impact Assessment**
   - What will improve (maintainability, performance, readability)
   - What could break (dependencies, integrations)
   - How to mitigate risks (tests, gradual rollout)

Output: Prioritized refactoring plan with risk assessment`
})
```

#### Agent 2: Current Code Quality and Safety Analysis

```javascript
Task({
  subagent_type: "code-reviewer",
  description: "Pre-refactoring code review",
  prompt: `Review code quality and identify safe refactoring opportunities.

Target: ${target_path}
Current code: ${code_context}

Analyze:
1. **Current State**
   - Code quality metrics (complexity, duplication)
   - Test coverage (what's safe to refactor)
   - Dependencies (what depends on this code)

2. **Refactoring Safety**
   - What has good test coverage (safe to refactor)
   - What lacks tests (needs tests first)
   - What is used by external consumers (breaking changes)

3. **Technical Debt Hotspots**
   - Most problematic areas
   - Quick wins (easy, high-value refactorings)
   - Long-term improvements (architectural changes)

4. **Risk Assessment**
   - Critical paths (be extra careful)
   - Non-critical code (can refactor aggressively)
   - Dead code candidates (safe to delete)

Output: Safe refactoring opportunities, risk assessment, test coverage gaps`
})
```

**Both agents run in PARALLEL** for comprehensive analysis

### Phase 2: Synthesize Refactoring Plan

**Combine agent insights:**

```markdown
## Refactoring Plan: ${target}

### Current State Analysis
- Code quality score: ${quality_score}/100
- Technical debt: ${debt_score}
- Test coverage: ${coverage_percentage}%
- Complexity hotspots: ${hotspot_count}

### Refactoring Strategy (Prioritized)

#### Tier 1: Safe Refactorings (Low Risk, High Value)
1. **Remove Dead Code**
   - ${dead_code_count} unused exports
   - ${unused_file_count} unused files
   - ${unused_dep_count} unused dependencies
   - Risk: Low (well-tested)
   - Impact: ${lines_removed} lines removed

2. **Extract Duplicated Code**
   - ${duplication_count} duplicate code blocks
   - Consolidate into shared utilities
   - Risk: Low (tests will catch issues)
   - Impact: Improved maintainability

#### Tier 2: Medium Risk Refactorings
1. **Reduce Function Complexity**
   - ${complex_function_count} functions with high complexity
   - Split into smaller functions
   - Risk: Medium (requires careful testing)
   - Impact: Improved readability

2. **Improve Abstractions**
   - ${abstraction_count} missing abstractions
   - Extract interfaces/classes
   - Risk: Medium
   - Impact: Better architecture

#### Tier 3: High Risk Refactorings
1. **Architectural Changes**
   - ${architecture_issue_count} architectural improvements
   - Risk: High (may need feature flags)
   - Impact: Long-term maintainability

### Implementation Strategy
- Start with Tier 1 (safe refactorings)
- Test after each change
- Move to Tier 2 only after Tier 1 complete
- Defer Tier 3 (requires more planning)

### Safety Constraints
- ${constraint_1}
- ${constraint_2}

### Success Metrics
- Lines removed: target ${target_lines}
- Complexity reduction: target ${complexity_target}
- Test coverage maintained: ${coverage_target}%
```

### Phase 3: User Confirmation

**Present plan and wait for approval:**

```markdown
## Refactoring Plan Ready

**Multi-agent analysis:**
- 🏗️ planner: ${opportunity_count} refactoring opportunities identified
- 🔍 code-reviewer: ${safe_count} safe refactorings, ${risky_count} need caution

**Expected Impact:**
- Lines removed: ~${lines_to_remove}
- Complexity reduction: ${complexity_improvement}%
- Test coverage maintained: ${coverage_percentage}%

**Refactoring Tiers:**
1. **Safe** (${safe_count}): Dead code removal, duplication
2. **Medium Risk** (${medium_count}): Complexity reduction
3. **High Risk** (${high_count}): Architectural changes (deferred)

**Next Steps:**
- ✅ Approve: Start with Tier 1 safe refactorings
- 📝 Modify: Adjust plan or priorities
- 🔬 Analyze: Need more detailed analysis

Would you like me to proceed?
```

### Phase 4: Step 1 - Detect Dead Code

Run analysis tools based on project type:

| Tool | What It Finds | Command |
|------|--------------|---------|
| knip | Unused exports, files, dependencies | `npx knip` |
| depcheck | Unused npm dependencies | `npx depcheck` |
| ts-prune | Unused TypeScript exports | `npx ts-prune` |
| vulture | Unused Python code | `vulture src/` |
| deadcode | Unused Go code | `deadcode ./...` |
| cargo-udeps | Unused Rust dependencies | `cargo +nightly udeps` |

If no tool is available, use Grep to find exports with zero imports:
```
# Find exports, then check if they're imported anywhere
```

## Step 2: Categorize Findings

Sort findings into safety tiers:

| Tier | Examples | Action |
|------|----------|--------|
| **SAFE** | Unused utilities, test helpers, internal functions | Delete with confidence |
| **CAUTION** | Components, API routes, middleware | Verify no dynamic imports or external consumers |
| **DANGER** | Config files, entry points, type definitions | Investigate before touching |

## Step 3: Safe Deletion Loop

For each SAFE item:

1. **Run full test suite** — Establish baseline (all green)
2. **Delete the dead code** — Use Edit tool for surgical removal
3. **Re-run test suite** — Verify nothing broke
4. **If tests fail** — Immediately revert with `git checkout -- <file>` and skip this item
5. **If tests pass** — Move to next item

## Step 4: Handle CAUTION Items

Before deleting CAUTION items:
- Search for dynamic imports: `import()`, `require()`, `__import__`
- Search for string references: route names, component names in configs
- Check if exported from a public package API
- Verify no external consumers (check dependents if published)

## Step 5: Consolidate Duplicates

After removing dead code, look for:
- Near-duplicate functions (>80% similar) — merge into one
- Redundant type definitions — consolidate
- Wrapper functions that add no value — inline them
- Re-exports that serve no purpose — remove indirection

## Step 6: Post-Refactoring Review

**Auto-launch code-reviewer for final verification:**

```javascript
Task({
  subagent_type: "code-reviewer",
  description: "Post-refactoring review",
  prompt: `Review refactoring results for quality and safety.

Refactoring completed: ${refactoring_summary}
Changes made: ${changes}
Tests status: ${test_status}

Verify:
- No functionality broken (all tests pass)
- Code quality improved (metrics better)
- No new issues introduced
- Refactoring goals achieved
- Documentation updated if needed

Provide:
- Quality improvement metrics
- Any issues found
- Suggestions for further improvement
- Approval status`
})
```

## Step 7: Summary

Report results:

```
Dead Code Cleanup
──────────────────────────────
Deleted:   12 unused functions
           3 unused files
           5 unused dependencies
Skipped:   2 items (tests failed)
Saved:     ~450 lines removed
──────────────────────────────
All tests passing ✅
```

---

## Rules

- **Never delete without running tests first**
- **One deletion at a time** — Atomic changes make rollback easy
- **Skip if uncertain** — Better to keep dead code than break production
- **Don't refactor while cleaning** — Separate concerns (clean first, refactor later)
- **Multi-agent planning** — Always run planner + code-reviewer before starting
- **Risk-aware** — Start with safe refactorings, defer high-risk changes

---

## Auto-Launch Conditions

This command automatically triggers when:
- User requests: "Refactor [code]"
- User requests: "Clean up dead code"
- User mentions: "リファクタリング", "コード整理"
- Keywords: "refactor", "clean", "remove dead code", "reduce complexity"

---

## Success Criteria

✅ Multi-agent analysis complete (planner + code-reviewer)
✅ Strategic refactoring plan created
✅ Safe refactorings identified and prioritized
✅ Tests pass after each change
✅ Code quality metrics improved
✅ No functionality broken
✅ Post-refactoring review complete

---

## Notes

- **Strategic approach:** Plan before refactoring (multi-agent analysis)
- **Safety first:** Start with safe refactorings (dead code, duplication)
- **Test-driven:** Run tests after every change
- **Atomic changes:** One refactoring at a time (easy rollback)
- **Risk-aware:** Defer high-risk architectural changes
