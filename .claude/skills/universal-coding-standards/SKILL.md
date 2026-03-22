---
name: universal-coding-standards
description: Language-agnostic coding standards for any project. Use this skill to maintain consistency, readability, testability, and long-term maintainability across all languages and frameworks.
origin: chang-pong
---

# Universal Coding Standards

This skill defines **language-agnostic** coding standards that apply to any codebase:
backend, frontend, scripting, infrastructure, tests, and tooling.

The goal is to keep code:
- Easy to read and understand
- Easy to change and extend
- Easy to test and debug
- Safe, performant, and robust in production

---

## When to Activate

Use this skill in any of the following situations:

- Writing new code in any language (backend, frontend, CLI, scripts, infra)
- Fixing bugs or regressions
- Refactoring existing modules or components
- Reviewing pull requests or merge requests
- Introducing new libraries, frameworks, or tools
- Designing new modules, APIs, or services

Always assume this skill is active as a **baseline standard** for all work,
in addition to any language-specific or project-specific guidelines.

---

## Code Quality Principles

### 1. Readability First
- Code is read more than it is written
- Use clear, descriptive names for variables, functions, and types
- Prefer self-documenting code over comments
- Maintain consistent formatting and style

### 2. KISS (Keep It Simple, Stupid)
- Choose the simplest solution that solves the problem
- Avoid over-engineering and premature abstractions
- Easy to understand is better than clever
- Complexity should be justified by clear benefits

### 3. DRY (Don't Repeat Yourself)
- Extract common logic into reusable functions or modules
- Avoid copy-paste programming
- Share utilities and abstractions when appropriate
- Balance DRY with readability (don't over-abstract)

### 4. YAGNI (You Aren't Gonna Need It)
- Don't build features before they're needed
- Avoid speculative generality
- Add complexity only when requirements demand it
- Start simple, refactor when patterns emerge

---

## Core Principles

1. **Clarity over cleverness**
   Prefer simple, explicit code over smart but hard-to-understand tricks.

2. **Consistency over personal style**
   Match the existing conventions of the project first, then improve them incrementally.

3. **Small, focused units**
   Functions, classes, and modules should do one thing well, with minimal side effects.

4. **Explicit data and control flow**
   Make dependencies, inputs, outputs, and side effects obvious and discoverable.

5. **Testability by design**
   Structure code so that behavior can be tested without heavy mocking or setup.

6. **Fail loudly in development, fail safely in production**
   Detect issues early, but avoid cascading failures or silent corruption in production.

7. **Document decisions, not the obvious**
   Comments and docs should explain *why* something is done, not what the code already says.

---

## Naming and Structure

### Naming

Use descriptive, intention-revealing names that communicate purpose clearly:

**Functions and methods** - Use verbs or verb phrases that describe actions:
- ✅ GOOD: `calculateTotal`, `sendEmail`, `loadUser`, `validateInput`, `processOrder`
- ❌ BAD: `total`, `email`, `user`, `input`, `process` (unclear what they do)

**Variables and properties** - Use nouns that describe data or state:
- ✅ GOOD: `totalPrice`, `userId`, `isActive`, `customerEmail`, `maxRetryCount`
- ❌ BAD: `x`, `temp`, `data`, `flag`, `num` (meaningless names)

**Types, classes, and interfaces** - Use nouns representing concepts or roles:
- ✅ GOOD: `User`, `OrderRepository`, `CacheClient`, `PaymentProcessor`, `EmailService`
- ❌ BAD: `Manager`, `Handler`, `Helper`, `Util` (too generic)

**Booleans** - Name as predicates (questions with yes/no answers):
- ✅ GOOD: `isValid`, `hasPermission`, `canDelete`, `shouldRetry`, `wasSuccessful`
- ❌ BAD: `valid`, `permission`, `delete`, `retry` (not clearly boolean)

**General rules:**
- Avoid abbreviations unless they are domain-standard and unambiguous (`id`, `url`, `http` are OK; `usr`, `msg`, `calc` are not)
- Use consistent naming conventions within a project (camelCase, snake_case, PascalCase)
- Longer names are acceptable if they improve clarity
- Context matters: `user` is clear in `getUserById()`, unclear as a standalone variable

### Files and Modules

- One **primary responsibility** per file or module.
- Group files by domain or feature (e.g., `users`, `billing`, `auth`), not by technical layer only.
- Avoid “misc” or “utils” dumping grounds. Split them when they grow too large or unfocused.
- Avoid cyclic dependencies between modules. If they appear, consider extracting a new shared abstraction.

---

## Functions, Methods, and Classes

### Functions and Methods

- Prefer small, composable functions with single responsibility.
- Avoid long parameter lists. Group related parameters into objects/structs where appropriate.
- Avoid global mutable state. Pass dependencies explicitly or via well-defined injection points.
- Avoid hidden behavior (e.g., functions that silently read/write global state, environment, or IO).

### Classes and Types

- Use composition over inheritance where possible.
- Keep public interfaces small and explicit.
- Hide internal details behind clear, documented interfaces.
- Avoid “god objects” that know or do too much.

---

## Error Handling and Logging

### Error Handling

- Fail fast when assumptions are violated in development environments.
- Validate inputs at the boundaries (APIs, public functions, external interfaces).
- Use clear, structured error types or error codes where the language allows.
- Do not silently swallow errors. If you catch an error, either:
  - Handle it fully, or
  - Wrap it with context and propagate it, or
  - Convert it into a safe, explicit fallback behavior.

### Logging

- Log events that matter for debugging, auditing, and operations.
- Avoid logging sensitive data (passwords, tokens, personal information).
- Use consistent log levels (debug, info, warn, error, fatal).
- Logs should be structured and parseable where possible (JSON, key-value, etc.).

---

## Testing Standards

These apply regardless of test framework or language.

### General

- Aim for meaningful coverage of critical paths, edge cases, and failure paths.
- Each test should have a clear Arrange–Act–Assert structure.
- Tests must be deterministic: no reliance on real time, randomness, or remote services without control.
- Tests should be fast enough to run frequently during development.

### Unit Tests

- Test small, isolated units of behavior.
- Avoid testing implementation details (private state, internal calls) when possible.
- Prefer behavior-based tests: assert outputs and observable side effects.

### Integration and System Tests

- Test how components interact: database, APIs, queues, external services.
- Use realistic but controlled data and environments.
- Clean up after tests to keep environments stable and repeatable.

### E2E / UI Tests

- Focus on core user journeys and business-critical flows.
- Use stable, semantic selectors or hooks.
- Avoid brittle tests that depend on internal implementation details (CSS classes, DOM structure).

---

## Performance and Resource Use

- Write straightforward code first; optimize when there is evidence of bottlenecks.
- Avoid premature micro-optimizations that hurt clarity.
- Be aware of algorithmic complexity for loops, nested loops, and large data structures.
- Release resources properly (files, connections, handles) or use language features that manage them safely (RAII, `defer`, `using`, similar constructs).

---

## Security and Safety

- Never hard-code secrets or credentials in code or configuration files under version control.
- Validate and sanitize all external inputs (HTTP requests, CLI args, file uploads, etc.).
- Be careful with:
  - String concatenation in queries and commands (avoid injections).
  - File system operations (paths, permissions).
  - Serialization and deserialization of untrusted data.
- Use secure defaults and least-privilege access where possible.

---

## Comments and Documentation

- Use comments to explain **why** the code exists or why a decision was made.
- Avoid comments that simply restate what the code clearly does.
- Keep high-level documentation (README, design docs) up to date with:
  - High-level architecture
  - Key domain concepts
  - Important invariants and constraints
- When deprecating code, mark it clearly and indicate the preferred alternative.

---

## Code Review Guidelines

When writing or reviewing code, always check:

1. Is the intent of the change clear from the code and commit/PR message?
2. Are names, structure, and responsibilities consistent with this skill?
3. Are tests present, meaningful, and passing?
4. Are error handling, logging, and edge cases considered?
5. Does this change introduce unnecessary complexity or premature optimization?
6. Is security, privacy, and performance impact acceptable?

Review comments should be:
- Respectful and constructive
- Focused on the code, not the author
- Specific, with actionable suggestions where possible

---

## Code Smell Detection

Watch for these anti-patterns and refactor when identified:

### 1. Long Functions
Functions that exceed 50-100 lines often do too much.

**Problem:** Hard to understand, test, and maintain.

**Solution:** Break into smaller, focused functions with clear responsibilities.

Example concept:
- ❌ BAD: 100-line function doing validation, transformation, and storage
- ✅ GOOD: Separate functions for `validate()`, `transform()`, `store()`

### 2. Deep Nesting
Code with 4+ levels of nested conditionals or loops.

**Problem:** Hard to follow logic, high cognitive load.

**Solution:** Use early returns, guard clauses, or extract nested logic into functions.

Example concept:
- ❌ BAD: `if (a) { if (b) { if (c) { if (d) { ... } } } }`
- ✅ GOOD: Early returns with guard clauses: `if (!a) return; if (!b) return; ...`

### 3. Magic Numbers and Strings
Unexplained literal values scattered throughout code.

**Problem:** Unclear meaning, hard to update consistently.

**Solution:** Extract into named constants with descriptive names.

Example concept:
- ❌ BAD: `if (retryCount > 3)` or `setTimeout(fn, 500)`
- ✅ GOOD: `const MAX_RETRIES = 3; const DEBOUNCE_DELAY_MS = 500`

### 4. Duplicated Code
Identical or nearly identical code blocks in multiple places.

**Problem:** Violates DRY, increases maintenance burden.

**Solution:** Extract common logic into shared functions or modules.

### 5. Large Classes or Modules
Classes/modules with too many responsibilities.

**Problem:** Violates Single Responsibility Principle, hard to test.

**Solution:** Split into smaller, focused units with clear boundaries.

### 6. Unclear Names
Variables, functions, or types with ambiguous or misleading names.

**Problem:** Readers must read implementation to understand purpose.

**Solution:** Rename to reveal intent and purpose clearly.

---

## Refactoring and Cleanup

- Refactor opportunistically: when touching code, leave it in a slightly better state.
- Avoid huge refactors without tests or without clear, incremental steps.
- Prefer a series of small, safe changes over one large risky change.
- Remove dead code and unused abstractions when identified.
- Apply code smell detection regularly and address issues systematically.

---

## Success Criteria

A codebase that follows this skill should have:

- Consistent naming, structure, and conventions across languages
- Clear, discoverable behavior and responsibilities
- Tests that provide confidence to change and refactor
- Minimal surprise for new contributors
- Reduced frequency of regressions caused by unclear or fragile code

---

**Remember**: these standards are a baseline.  
Language-specific and project-specific guidelines can further refine them,  
but should never contradict the core principles of clarity, consistency, and safety.
