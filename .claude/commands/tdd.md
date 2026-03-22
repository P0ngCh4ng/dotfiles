# TDD - Test-Driven Development Workflow

Enforce test-driven development workflow. Scaffold interfaces, generate tests FIRST, then implement minimal code to pass. Ensure 80%+ coverage.

$ARGUMENTS

---

## TDD Workflow

### Phase 1: Requirements Analysis

1. **Parse Requirements**
   - Understand feature/functionality to implement: $ARGUMENTS
   - Clarify expected behavior and edge cases
   - Identify acceptance criteria

2. **Context Gathering**
   - Find existing test files (use Glob: `**/*.{test,spec}.{js,ts,py,go,rb}`)
   - Understand testing conventions and patterns
   - Identify test framework in use (Jest, pytest, Go testing, RSpec, etc.)
   - Check coverage configuration

3. **Multi-Agent Review**

   **Launch `planner` agent** to analyze requirements and suggest test cases:

   ```
   Task({
     subagent_type: "planner",
     description: "TDD test case planning",
     prompt: "Analyze requirements and suggest comprehensive test cases for: $ARGUMENTS\n\nInclude:\n- Happy path scenarios\n- Edge cases\n- Error scenarios\n- Boundary conditions\n\nContext: [gathered context]"
   })
   ```

### Phase 2: Interface Definition (Red Phase - Part 1)

**Before writing tests, define the interface:**

1. **Scaffold Function/Class Signatures**
   - Define function signatures with type hints (if applicable)
   - Define class interfaces with method signatures
   - Add docstrings/comments explaining expected behavior
   - DO NOT implement logic yet (use `pass`, `return null`, `panic("not implemented")`, etc.)

2. **Define Data Models**
   - Define input/output types
   - Define constants and enums
   - Define error types

**Example (Python)**:
```python
def calculate_discount(price: float, discount_rate: float) -> float:
    """
    Calculate discounted price.

    Args:
        price: Original price (must be positive)
        discount_rate: Discount rate (0.0 to 1.0)

    Returns:
        Discounted price

    Raises:
        ValueError: If price is negative or discount_rate is invalid
    """
    raise NotImplementedError("To be implemented via TDD")
```

### Phase 3: Write Tests FIRST (Red Phase - Part 2)

**Write comprehensive tests BEFORE implementation:**

1. **Happy Path Tests**
   - Test normal, expected inputs
   - Verify correct outputs

2. **Edge Case Tests**
   - Test boundary values (0, empty, max, min)
   - Test special characters and formats
   - Test null/None/undefined handling

3. **Error Scenario Tests**
   - Test invalid inputs
   - Test exception handling
   - Test error messages

4. **Integration Tests** (if applicable)
   - Test interactions with other components
   - Test database operations
   - Test API calls

**Test Template**:
```javascript
describe('calculateDiscount', () => {
  // Happy path
  test('calculates discount correctly for valid inputs', () => {
    expect(calculateDiscount(100, 0.1)).toBe(90)
  })

  // Edge cases
  test('handles zero discount rate', () => {
    expect(calculateDiscount(100, 0)).toBe(100)
  })

  test('handles 100% discount', () => {
    expect(calculateDiscount(100, 1.0)).toBe(0)
  })

  // Error scenarios
  test('throws error for negative price', () => {
    expect(() => calculateDiscount(-100, 0.1)).toThrow('Price must be positive')
  })

  test('throws error for invalid discount rate', () => {
    expect(() => calculateDiscount(100, 1.5)).toThrow('Discount rate must be between 0 and 1')
  })
})
```

5. **Run Tests (Expect Failure)**
   - All tests should FAIL at this stage (Red Phase)
   - Verify tests are actually running
   - Confirm failure messages are clear

### Phase 4: Implement Minimal Code (Green Phase)

**Write the SIMPLEST code to make tests pass:**

1. **Implement Core Logic**
   - Start with the simplest approach
   - Don't optimize prematurely
   - Focus on making tests pass

2. **Run Tests After Each Change**
   - Verify tests pass incrementally
   - Fix any failing tests immediately
   - Aim for all tests passing (Green Phase)

3. **Verify Coverage**
   - Run coverage report
   - Ensure 80%+ line coverage
   - Ensure 80%+ branch coverage
   - Add missing tests if coverage is low

**Coverage Commands by Framework**:
- **Jest**: `npm test -- --coverage`
- **pytest**: `pytest --cov=.`
- **Go**: `go test -cover`
- **RSpec**: `bundle exec rspec --format documentation`

### Phase 5: Refactor (Refactor Phase)

**Improve code quality while keeping tests passing:**

1. **Launch `code-reviewer` agent** in parallel with your own review:

   ```
   Task({
     subagent_type: "code-reviewer",
     description: "Review TDD implementation",
     prompt: "Review the following TDD implementation for quality, security, and best practices:\n\n[Code context]\n\nEnsure:\n- Tests are comprehensive\n- Implementation is clean and maintainable\n- Security best practices are followed\n- Coverage is sufficient"
   })
   ```

2. **Refactor Based on Review**
   - Remove duplication (DRY principle)
   - Improve naming and clarity
   - Optimize if needed (but keep it simple)
   - Extract helper functions/methods
   - Add comments for complex logic

3. **Re-run Tests After Each Refactor**
   - Ensure no regression
   - Keep all tests green
   - Update tests if interface changes

### Phase 6: Documentation and Commit

1. **Update Documentation**
   - Add usage examples
   - Document edge cases and limitations
   - Update API documentation

2. **Final Coverage Check**
   - Run coverage report one more time
   - Ensure 80%+ coverage achieved
   - Add missing tests if needed

3. **Commit with TDD Message**
   ```bash
   git add .
   git commit -m "feat: implement [feature] via TDD

   - Write comprehensive test suite (80%+ coverage)
   - Implement minimal code to pass tests
   - Refactor for quality and maintainability

   🤖 Generated with [Claude Code](https://claude.com/claude-code)

   Co-Authored-By: Claude <noreply@anthropic.com>"
   ```

---

## TDD Principles

1. **Red-Green-Refactor Cycle**
   - RED: Write failing test
   - GREEN: Write minimal code to pass
   - REFACTOR: Improve code quality

2. **Test First, Code Second**
   - ALWAYS write tests before implementation
   - Tests define the API/interface
   - Tests serve as documentation

3. **Minimal Implementation**
   - Write the simplest code that passes tests
   - Don't add features not covered by tests
   - YAGNI (You Ain't Gonna Need It)

4. **Continuous Testing**
   - Run tests after every small change
   - Keep tests passing at all times
   - Fix broken tests immediately

5. **High Coverage**
   - Target 80%+ line coverage
   - Target 80%+ branch coverage
   - Cover edge cases and error scenarios

---

## Auto-Launch Conditions

This command automatically triggers when user requests:
- "Write tests for [feature]"
- "TDD for [feature]"
- "Test-driven [feature]"
- "Implement [feature] with tests"

---

## Multi-Agent Integration

**ALWAYS launch `code-reviewer` agent** after implementation:
- Review test quality and coverage
- Review implementation for best practices
- Check for security vulnerabilities
- Suggest improvements

**Launch in parallel whenever possible:**
- Planning phase: `planner` agent
- Review phase: `code-reviewer` agent

---

## Coverage Targets

- **Minimum**: 80% line coverage, 80% branch coverage
- **Recommended**: 90%+ coverage for critical paths
- **100% coverage**: For security-critical code

---

## Success Criteria

✅ All tests pass (Green Phase)
✅ 80%+ code coverage achieved
✅ Code reviewed by `code-reviewer` agent
✅ Refactored for quality and maintainability
✅ Documentation updated
✅ Committed with descriptive message
