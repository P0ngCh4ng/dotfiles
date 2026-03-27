# Bug Prevention and Logical Error Detection Rules

## Purpose

Prevent bugs and logical errors through:
1. **Multi-agent verification** (multiple perspectives catch more issues)
2. **Systematic checks** (checklists for common bug patterns)
3. **Early detection** (catch issues in planning phase, not implementation phase)
4. **Automated reviews** (consistent quality without manual oversight)

---

## Multi-Agent Bug Prevention Strategy

### Strategy 1: Planning Phase Verification

**Before implementation, launch multiple agents to catch issues early:**

```javascript
// Launch planner + code-reviewer in PARALLEL during planning
Task({ subagent_type: "planner", ... })
Task({ subagent_type: "code-reviewer", ... })

// Agents will identify:
// - Logical flaws in approach
// - Security vulnerabilities
// - Performance bottlenecks
// - Edge cases not considered
```

**Benefits**:
- 🛡️ Catch issues BEFORE writing code (cheaper to fix)
- 🔍 Multiple perspectives (planner focuses on architecture, reviewer on security/quality)
- ⚡ Faster than fixing bugs after implementation

---

### Strategy 2: Post-Implementation Verification

**After significant code changes, auto-launch code-reviewer:**

```javascript
// Automatically triggered after:
// - 3+ files modified
// - 100+ lines changed
// - Before git commit

Task({
  subagent_type: "code-reviewer",
  description: "Post-implementation review",
  prompt: "Review recent changes for bugs, security issues, and quality concerns..."
})
```

**What code-reviewer catches**:
- Security vulnerabilities (SQL injection, XSS, etc.)
- Logic errors (off-by-one, null pointer, race conditions)
- Code quality issues (duplication, complexity, maintainability)
- Missing error handling
- Inadequate input validation

---

### Strategy 3: Test-Driven Development (TDD)

**Use `/tdd` command with multi-agent workflow:**

1. **`planner` agent** → Suggests comprehensive test cases (including edge cases)
2. **Write tests FIRST** → Tests define expected behavior
3. **Implement minimal code** → Only what's needed to pass tests
4. **`code-reviewer` agent** → Reviews tests + implementation for quality

**Benefits**:
- ✅ Tests catch regressions immediately
- 🎯 Clear success criteria (all tests pass)
- 📊 Measurable coverage (80%+ target)
- 🔁 Fast feedback loop (instant detection of breaks)

---

## Common Bug Patterns and Prevention

### Bug Pattern 1: Off-By-One Errors

**Common in**:
- Array indexing (`arr[length]` instead of `arr[length - 1]`)
- Loop bounds (`for i < n` vs `for i <= n`)
- String slicing (`str[0:n]` vs `str[0:n+1]`)

**Prevention**:
- ✅ Write tests for boundary conditions (first, last, empty)
- ✅ Use language-safe idioms (e.g., Python `arr[-1]` for last element)
- ✅ Code reviewer checks loop bounds

**Agent Detection**:
```javascript
// code-reviewer will flag:
// "Loop may have off-by-one error: check boundary condition"
// "Array access may be out of bounds: verify index < length"
```

---

### Bug Pattern 2: Null/Undefined/None Handling

**Common in**:
- Accessing properties of null objects
- Not checking function return values
- Assuming data exists without validation

**Prevention**:
- ✅ Always validate inputs (null checks, type checks)
- ✅ Use optional chaining (`obj?.property`)
- ✅ Provide default values (`value ?? default`)
- ✅ Write tests for null/undefined cases

**Agent Detection**:
```javascript
// code-reviewer will flag:
// "Potential null pointer dereference: add null check"
// "Function may return null but caller doesn't handle it"
```

---

### Bug Pattern 3: Race Conditions and Concurrency Issues

**Common in**:
- Async/await without proper synchronization
- Shared state modification without locks
- Database transactions without isolation

**Prevention**:
- ✅ Use locks/mutexes for shared state
- ✅ Minimize shared mutable state
- ✅ Use atomic operations where possible
- ✅ Test concurrent scenarios

**Agent Detection**:
```javascript
// code-reviewer will flag:
// "Potential race condition: shared state modified without lock"
// "Async operation may cause race condition"
```

---

### Bug Pattern 4: Input Validation Failures

**Common in**:
- Not validating user inputs
- Trusting client-side validation
- Missing range/format checks

**Prevention**:
- ✅ Validate ALL inputs at API boundary
- ✅ Use schema validation (Joi, Yup, Zod, Pydantic)
- ✅ Sanitize inputs to prevent injection
- ✅ Test with malicious/invalid inputs

**Agent Detection**:
```javascript
// code-reviewer will flag:
// "Missing input validation: potential security risk"
// "User input used without sanitization: SQL injection risk"
```

---

### Bug Pattern 5: Error Handling Omissions

**Common in**:
- Not catching exceptions
- Swallowing errors silently
- Not logging errors for debugging

**Prevention**:
- ✅ Wrap risky operations in try-catch
- ✅ Log errors with context (stack trace, inputs)
- ✅ Return meaningful error messages
- ✅ Test error scenarios

**Agent Detection**:
```javascript
// code-reviewer will flag:
// "No error handling for async operation"
// "Error caught but not logged: debugging will be difficult"
```

---

### Bug Pattern 6: Memory Leaks

**Common in**:
- Not closing resources (files, connections, streams)
- Event listeners not removed
- Circular references in closures

**Prevention**:
- ✅ Use RAII patterns (resource acquisition is initialization)
- ✅ Close resources in finally blocks
- ✅ Remove event listeners when done
- ✅ Use weak references where appropriate

**Agent Detection**:
```javascript
// code-reviewer will flag:
// "Resource opened but not closed: potential memory leak"
// "Event listener added but never removed"
```

---

### Bug Pattern 7: Logic Errors in Conditionals

**Common in**:
- Wrong comparison operators (`=` vs `==` vs `===`)
- Incorrect boolean logic (AND vs OR)
- Missing edge case handling

**Prevention**:
- ✅ Write tests for all branches (if/else, switch cases)
- ✅ Use strict equality (`===` in JavaScript)
- ✅ Simplify complex conditionals (extract to functions)
- ✅ Consider all edge cases in planning phase

**Agent Detection**:
```javascript
// planner will catch during planning:
// "Edge case not considered: what if value is 0?"
// code-reviewer will catch during review:
// "Complex conditional logic: consider extracting to function"
```

---

## Systematic Bug Detection Checklist

### Before Implementation (Planning Phase)

**Launch `planner` agent to verify:**
- [ ] All requirements are clear and unambiguous
- [ ] Edge cases are identified (empty, zero, null, max, min)
- [ ] Error scenarios are planned (network failure, invalid input, timeout)
- [ ] Dependencies and order are correct
- [ ] No logical contradictions in requirements

**Launch `code-reviewer` agent to pre-analyze:**
- [ ] Security implications of proposed approach
- [ ] Performance bottlenecks in design
- [ ] Potential race conditions or concurrency issues
- [ ] Input validation strategy
- [ ] Error handling strategy

---

### During Implementation

**Self-check (as you write code):**
- [ ] Every input is validated
- [ ] Every error is handled or logged
- [ ] Every resource is closed/cleaned up
- [ ] Every loop has correct bounds
- [ ] Every null/undefined is checked
- [ ] Every async operation is awaited or handled

**Write tests for:**
- [ ] Happy path (expected inputs)
- [ ] Edge cases (boundary values)
- [ ] Error scenarios (invalid inputs, exceptions)
- [ ] Concurrency scenarios (if applicable)

---

### After Implementation (Review Phase)

**Auto-launch `code-reviewer` agent to verify:**
- [ ] No security vulnerabilities (injection, XSS, etc.)
- [ ] No logic errors (off-by-one, null pointer, etc.)
- [ ] Proper error handling throughout
- [ ] Input validation at all boundaries
- [ ] Resource cleanup (no memory leaks)
- [ ] Code quality (maintainability, readability)
- [ ] Test coverage (80%+ target)

---

### Before Commit

**Final checks:**
- [ ] All tests pass
- [ ] Code coverage meets target (80%+)
- [ ] No console.log or debug statements
- [ ] Documentation updated
- [ ] `code-reviewer` agent has reviewed changes

---

## Multi-Agent Verification Workflow

### Comprehensive Bug Prevention Flow

```
1. USER REQUEST
   ↓
2. LAUNCH PLANNER (architecture + edge cases)
   ↓
3. LAUNCH CODE-REVIEWER (security + quality pre-analysis)
   ↓
4. SYNTHESIZE AGENT FEEDBACK
   ↓
5. CREATE COMPREHENSIVE PLAN
   - Includes edge cases
   - Includes error handling strategy
   - Includes security considerations
   ↓
6. IMPLEMENT WITH TDD
   - Write tests first (including edge cases)
   - Implement minimal code
   - Run tests continuously
   ↓
7. LAUNCH CODE-REVIEWER (post-implementation review)
   ↓
8. REFACTOR BASED ON FEEDBACK
   - Fix identified issues
   - Improve code quality
   ↓
9. VERIFY
   - All tests pass
   - 80%+ coverage
   - No security issues
   ↓
10. COMMIT
```

**Result**: Bugs caught at EVERY stage (planning, implementation, review)

---

## Agent Collaboration for Logic Error Detection

### Example: Feature Planning with Bug Prevention

```javascript
// 1. User requests feature
const requirement = "Implement user discount calculation"

// 2. Launch planner to identify edge cases
Task({
  subagent_type: "planner",
  prompt: `Plan implementation for: ${requirement}

  CRITICAL: Identify ALL edge cases:
  - What if price is 0?
  - What if discount rate is negative?
  - What if discount rate > 100%?
  - What if user is null?
  - What about currency precision?`
})

// 3. Launch code-reviewer to identify security/quality issues
Task({
  subagent_type: "code-reviewer",
  prompt: `Pre-analyze security and quality for: ${requirement}

  Check for:
  - Input validation requirements
  - Potential integer overflow
  - Floating point precision issues
  - Authentication/authorization needs`
})

// 4. Synthesize findings
// - Planner identifies: "Need to handle negative discount rate"
// - Code-reviewer identifies: "Must validate user authorization before applying discount"
// - Combined plan includes BOTH considerations

// 5. Result: Comprehensive plan that prevents bugs BEFORE coding
```

---

## Metrics: Measuring Bug Prevention Success

**Track these metrics to evaluate multi-agent bug prevention:**

1. **Bugs Caught in Planning Phase**
   - Goal: 50%+ of potential bugs caught before coding
   - Measured by: Agent feedback that prevents issues

2. **Bugs Caught in Review Phase**
   - Goal: 40%+ of remaining bugs caught by code-reviewer
   - Measured by: Issues identified in post-implementation review

3. **Bugs Reaching Production**
   - Goal: < 10% of bugs reach production
   - Measured by: Bug reports after deployment

4. **Test Coverage**
   - Goal: 80%+ line coverage, 80%+ branch coverage
   - Measured by: Coverage reports

5. **Time to Fix**
   - Goal: Faster fixes (issues caught early are cheaper)
   - Measured by: Hours spent fixing bugs

---

## Integration with Slash Commands

### `/plan` Command
**Bug Prevention**:
- Auto-launch `planner` + `code-reviewer` in parallel
- Planner identifies edge cases and logic errors
- Code-reviewer identifies security and quality issues
- Synthesized plan includes bug prevention strategies

### `/tdd` Command
**Bug Prevention**:
- Planner suggests comprehensive test cases (including edge cases)
- Write tests FIRST (define expected behavior)
- Implement to pass tests (test-driven prevents logic errors)
- Code-reviewer reviews tests + implementation

### `/quality-gate` Command
**Bug Prevention**:
- Auto-launch `code-reviewer` for comprehensive analysis
- Run linters, type checkers, security scanners
- Ensure tests pass and coverage meets target
- Block deployment if issues found

---

## Best Practices Summary

### ✅ DO:
- Launch multiple agents for comprehensive analysis
- Write tests before implementation (TDD)
- Validate ALL inputs at API boundaries
- Handle ALL errors explicitly
- Review code before committing (auto-launch code-reviewer)
- Test edge cases and error scenarios
- Aim for 80%+ test coverage

### ❌ DON'T:
- Skip planning phase (bugs are cheaper to fix in planning)
- Skip code review (human or agent)
- Trust user inputs without validation
- Swallow errors silently (always log)
- Commit without running tests
- Ignore agent feedback (agents catch real issues)

---

## Continuous Improvement

**Quarterly Review**:
- Analyze bug patterns in production
- Update this document with new patterns
- Refine agent prompts to catch more issues
- Improve slash command automation

**When a bug reaches production**:
- [ ] Document the bug pattern
- [ ] Update agent instructions to catch similar bugs
- [ ] Add to this prevention guide
- [ ] Create test case to prevent regression
