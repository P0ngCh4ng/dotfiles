# Bug Prevention and Logical Error Detection

Catch bugs as early as possible: plan with multiple agents, write tests first, review after implementation.

## Flow

```
Request → planner ∥ code-reviewer (pre-analysis) → synthesized plan (edge cases, error handling, security)
        → TDD (tests first, minimal impl) → code-reviewer (post-impl) → fix feedback → verify → commit
```

- **Planning**: `planner` finds logical flaws, edge cases, dependency/order issues; `code-reviewer` checks security implications, performance bottlenecks, race conditions, validation and error-handling strategy.
- **Post-implementation**: launch `code-reviewer` after 3+ files / 100+ lines changed, and before commit.
- **TDD**: `/tdd` — planner proposes test cases incl. edge cases → tests first → implement → review. 80%+ coverage.

When briefing `planner`, list concrete edge cases to examine (zero, negative, > max, null user, currency precision…); when briefing `code-reviewer`, list concrete risks (validation, overflow, float precision, authz).

## Common Bug Patterns

| Pattern | Typical cause | Prevention |
|---|---|---|
| Off-by-one | `arr[length]`, `<` vs `<=`, slice bounds | Test first/last/empty; prefer safe idioms (`arr[-1]`, iterators) |
| Null / undefined | Unchecked return values, assumed data | Validate inputs, `?.`, `??` defaults, test null cases |
| Race conditions | Unsynchronized async, shared mutable state, weak tx isolation | Minimize shared state, locks/atomics, test concurrency |
| Input validation | Trusting client, missing range/format checks | Schema validation (Zod, Joi, Pydantic…) at every boundary; sanitize against injection |
| Error handling | Uncaught exceptions, swallowed errors, no logs | try/catch risky ops, log with context, meaningful messages, test error paths |
| Resource leaks | Unclosed files/connections/streams, listeners never removed | Close in `finally` / RAII, remove listeners, weak refs where apt |
| Conditional logic | `=`/`==`/`===`, AND vs OR, missed branches | Strict equality, extract complex conditions, test every branch |

## Checklists

**While coding** — every input validated · every error handled or logged · every resource closed · loop bounds checked · null checked · every async awaited or handled.

**Tests** — happy path · boundary values · invalid input / exceptions · concurrency (if applicable).

**Before commit** — all tests pass · coverage ≥ 80% · no `console.log`/debug code · docs updated · `code-reviewer` has reviewed.

## When a Bug Reaches Production

Document the pattern here, add a regression test, and tighten agent prompts so similar bugs get caught.
