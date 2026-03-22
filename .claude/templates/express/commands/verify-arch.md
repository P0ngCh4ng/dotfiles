# Verify Express Architecture

Run comprehensive architecture validation on Express.js codebase to ensure adherence to MVC + Service Layer patterns.

## Validation Process

Follow these steps to verify the architecture:

### 1. Scan Project Structure

Check that the directory structure matches the expected layout:

```
src/
├── routes/
├── controllers/
├── services/
├── models/
├── middlewares/
├── utils/
├── config/
├── validators/
├── app.js
└── server.js
```

**Action**: List all directories and verify structure exists.

### 2. Validate File Naming Conventions

Check each file follows naming conventions:

#### Routes
- ✅ Pattern: `*.routes.js` (e.g., `users.routes.js`)
- ✅ Location: `src/routes/`
- ✅ Plural naming

#### Controllers
- ✅ Pattern: `*.controller.js` (e.g., `users.controller.js`)
- ✅ Location: `src/controllers/`
- ✅ Plural naming

#### Services
- ✅ Pattern: `*.service.js` (e.g., `users.service.js`)
- ✅ Location: `src/services/`
- ✅ Plural naming

#### Models
- ✅ Pattern: `*.model.js` (e.g., `user.model.js`)
- ✅ Location: `src/models/`
- ✅ Singular naming

#### Middleware
- ✅ Pattern: `*.middleware.js` (e.g., `auth.middleware.js`)
- ✅ Location: `src/middlewares/`

**Action**: Find all files with `*.js` extension in `src/` and validate naming.

### 3. Check Layer Separation

For each file, validate it follows layer responsibilities:

#### Routes Validation

Search for violations in `src/routes/*.routes.js`:

**Anti-patterns to detect**:
- ❌ `await` keyword (async logic in routes)
- ❌ Direct model imports (e.g., `require('../models/user.model')`)
- ❌ Business logic (if statements with business rules)
- ❌ `res.json()` or `res.send()` (response handling)

**Expected patterns**:
- ✅ Controller imports only
- ✅ Middleware usage
- ✅ Route definitions only

**Check**:
```bash
# Search for violations in routes
grep -r "await" src/routes/ --include="*.routes.js"
grep -r "require.*models" src/routes/ --include="*.routes.js"
grep -r "res\.json\|res\.send" src/routes/ --include="*.routes.js"
```

#### Controllers Validation

Search for violations in `src/controllers/*.controller.js`:

**Anti-patterns to detect**:
- ❌ Direct model imports (e.g., `const User = require('../models/user.model')`)
- ❌ Business logic (complex if/else, business rules)
- ❌ Missing try-catch for async functions
- ❌ Not calling `next(error)` in catch blocks
- ❌ Inconsistent response format

**Expected patterns**:
- ✅ Service imports only
- ✅ Try-catch blocks
- ✅ `next(error)` in catch
- ✅ Standard response format

**Check**:
```javascript
// Controllers should have this pattern:
exports.methodName = async (req, res, next) => {
  try {
    // Extract data from request
    const data = await serviceMethod(req.body);

    // Return standard format
    res.status(200).json({
      success: true,
      data: data
    });
  } catch (error) {
    next(error);
  }
};
```

**Validation**:
```bash
# Check for direct model imports in controllers
grep -r "require.*models" src/controllers/ --include="*.controller.js"

# Check for missing try-catch
# (manual review - check if async functions have try-catch)
```

#### Services Validation

Search for violations in `src/services/*.service.js`:

**Anti-patterns to detect**:
- ❌ HTTP-specific code (`req`, `res`, `next` parameters)
- ❌ Response formatting (res.json, res.status)
- ❌ Route definitions

**Expected patterns**:
- ✅ Business logic
- ✅ Model/database access
- ✅ Throwing custom errors
- ✅ Pure business functions

**Check**:
```bash
# Search for HTTP objects in services
grep -r "req\|res\|next" src/services/ --include="*.service.js"
grep -r "res\.json\|res\.send\|res\.status" src/services/ --include="*.service.js"
```

### 4. Validate Response Format

Check all controller responses use standard format:

**Expected Success Format**:
```javascript
{
  success: true,
  data: {},
  message: "optional"
}
```

**Expected Error Format** (in error handler):
```javascript
{
  success: false,
  error: {
    code: "ERROR_CODE",
    message: "Error message"
  }
}
```

**Action**: Search for `res.json()` calls and validate format.

```bash
# Find all response calls
grep -rn "res\.json\|res\.status.*\.json" src/controllers/
```

### 5. Check Error Handling

Validate error handling patterns:

**Check for**:
- ✅ Global error handler middleware exists
- ✅ All async functions have try-catch
- ✅ Errors passed to next() in controllers
- ✅ Custom error classes defined
- ✅ AsyncHandler wrapper used (optional but recommended)

**Action**:
```bash
# Check for global error handler
grep -r "app\.use.*err.*req.*res.*next" src/app.js

# Check for custom errors
ls src/utils/errors.js

# Verify async functions have try-catch
# (manual review of controller files)
```

### 6. Validate Middleware Usage

Check middleware patterns:

**For each middleware in `src/middlewares/`**:
- ✅ Calls `next()` or sends response
- ✅ Async middleware is wrapped
- ✅ Proper error handling

**Action**:
```bash
# Check middleware files
find src/middlewares/ -name "*.middleware.js"

# Check for next() calls
grep -r "next()" src/middlewares/
```

### 7. Database Access Audit

Ensure ONLY services access the database:

**Action**:
```bash
# Find all model imports
grep -r "require.*models" src/

# Should ONLY appear in:
# - src/services/*.service.js
# - src/app.js (for connection setup)
# - src/server.js (for connection setup)

# Should NOT appear in:
# - src/controllers/*.controller.js
# - src/routes/*.routes.js
# - src/middlewares/*.middleware.js
```

### 8. Check Async/Await Usage

Validate async operations are handled correctly:

**Check for**:
- ❌ Missing await on promises
- ❌ Mixing callbacks and async/await
- ❌ Sequential awaits when parallel is possible

**Action**: Manual code review of async functions.

### 9. Validation Summary Report

Generate a summary report:

```markdown
# Architecture Validation Report

## File Structure: ✅ PASS / ❌ FAIL
- Routes: X files
- Controllers: X files
- Services: X files
- Models: X files
- Middleware: X files

## Naming Conventions: ✅ PASS / ❌ FAIL
- Violations found: [list]

## Layer Separation: ✅ PASS / ❌ FAIL
- Routes violations: [list]
- Controllers violations: [list]
- Services violations: [list]

## Response Format: ✅ PASS / ❌ FAIL
- Inconsistent formats: [list]

## Error Handling: ✅ PASS / ❌ FAIL
- Global error handler: ✅/❌
- Missing try-catch: [list]
- Custom errors defined: ✅/❌

## Database Access: ✅ PASS / ❌ FAIL
- Improper access in: [list]

## Overall Result: ✅ PASS / ❌ FAIL

### Action Items:
1. [Issue 1 and fix]
2. [Issue 2 and fix]
...
```

---

## Usage

Run this command from the project root:

```bash
# Full validation
claude verify-arch

# Validate specific files
claude verify-arch src/controllers/users.controller.js

# Quick check (critical issues only)
claude verify-arch --quick

# Auto-fix common issues
claude verify-arch --fix
```

---

## Quick Validation Checklist

Use this for rapid manual checks:

```
□ All routes files end with .routes.js
□ All controller files end with .controller.js
□ All service files end with .service.js
□ All model files end with .model.js
□ Routes only define endpoints
□ Controllers have no business logic
□ Controllers don't import models
□ Services contain all business logic
□ Only services import models
□ All async functions have try-catch
□ All errors passed to next()
□ Response format is consistent
□ Global error handler exists
□ Custom error classes defined
□ Middleware calls next()
□ Input validation on all routes
□ Authentication middleware applied
```

---

## Auto-Fix Common Issues

For common violations, provide auto-fix:

### Fix: Controller accessing model directly

**Before**:
```javascript
// src/controllers/users.controller.js
const User = require('../models/user.model');

exports.getUsers = async (req, res, next) => {
  try {
    const users = await User.find();
    res.json(users);
  } catch (error) {
    next(error);
  }
};
```

**Auto-fix**:
1. Create service method
2. Update controller to use service
3. Remove model import from controller

**After**:
```javascript
// src/controllers/users.controller.js
const userService = require('../services/users.service');

exports.getUsers = async (req, res, next) => {
  try {
    const users = await userService.getAllUsers();
    res.json({ success: true, data: users });
  } catch (error) {
    next(error);
  }
};

// src/services/users.service.js (new)
const User = require('../models/user.model');

exports.getAllUsers = async () => {
  return await User.find().lean();
};
```

---

## Integration with CI/CD

Add to GitHub Actions:

```yaml
name: Architecture Validation

on: [push, pull_request]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Validate Architecture
        run: |
          npm run verify-arch
      - name: Report Results
        if: failure()
        run: |
          echo "Architecture validation failed. See report above."
```

---

**Goal**: Ensure 100% compliance with Express MVC + Service Layer architecture.
