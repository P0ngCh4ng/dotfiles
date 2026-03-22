---
description: Verify Next.js architecture compliance and optionally auto-fix violations
argument-hint: [--fix]
allowed-tools: [Read, Glob, Grep, Bash, Edit, Write]
---

# Architecture Verification Command

Performs comprehensive verification of Next.js architecture compliance.

## Arguments

Arguments provided: $ARGUMENTS

- `--fix`: Automatically fix violations where possible

## Verification Checks

This command performs the following validations:

### 1. Directory Structure Compliance

Verify that all features follow the required structure:
```
src/features/[feature-name]/
├── api/          # Business logic for API routes
├── components/   # Feature-specific UI
├── hooks/        # React hooks (client-side)
├── types/        # TypeScript definitions
├── actions/      # Server Actions
└── __tests__/    # Tests
```

**Check:**
- Each feature has required directories
- No files exist outside allowed directories
- Proper file naming conventions (PascalCase for components, camelCase for utilities)

### 2. Client Component Directive Validation

**Check:**
- Components using React hooks (useState, useEffect, etc.) have "use client" directive
- "use client" is on the first line
- Server components don't unnecessarily use "use client"

**Detection command:**
```bash
# Find components missing "use client" but using hooks
grep -rl "useState\|useEffect\|useCallback\|useMemo\|useRef" src/features/*/components/ | \
  xargs grep -L '"use client"'
```

**Fix:**
Add "use client" directive to the first line of affected files.

### 3. API Response Format Validation

**Required format:**
```typescript
// Success
NextResponse.json({ data: result })

// Error
NextResponse.json({ error: message, code: ERROR_CODE }, { status: 500 })
```

**Check:**
- All API routes return responses wrapped in `{ data: ... }`
- Error responses include both `error` and `code` fields
- Proper HTTP status codes are used

**Detection command:**
```bash
# Find non-compliant API routes
grep -r "NextResponse.json" src/features/*/api/ src/app/api/ | grep -v "{ data:"
```

**Fix:**
Wrap existing responses in proper format.

### 4. Database Schema Validation

**Check:**
- All models have required fields: `id`, `createdAt`, `updatedAt`
- Soft delete support: `deletedAt` field for relevant models
- Proper indexes on frequently queried fields
- Relations are properly defined

**Validation command:**
```bash
npm run db:validate
```

### 5. Test Coverage Check

**Requirement:** 80% minimum coverage per feature

**Check:**
```bash
npm run test:coverage -- src/features/
```

**Report:**
- Features below 80% threshold
- Uncovered critical paths
- Missing test files

### 6. Type Safety Validation

**Check:**
```bash
npm run type-check
```

**Verify:**
- No TypeScript errors
- Proper type definitions in `types/` directories
- API route handlers have proper types

## Implementation Steps

When this command is executed:

1. **Parse arguments** to check if `--fix` mode is enabled

2. **Directory Structure Check:**
   - Use Glob to find all feature directories: `src/features/*/`
   - For each feature, verify required subdirectories exist
   - Check for misplaced files outside allowed structure
   - Report violations

3. **Client Component Directive Check:**
   - Search for hook usage: `grep -rl "useState\|useEffect" src/features/*/components/`
   - For each file found, check if "use client" exists on line 1
   - If `--fix` enabled: Add directive to first line
   - Report affected files

4. **API Response Format Check:**
   - Find all API route files: `src/features/*/api/route.ts` and `src/app/api/**/route.ts`
   - Search for `NextResponse.json(` calls
   - Verify format matches `{ data: ... }` or `{ error: ..., code: ... }`
   - If `--fix` enabled: Wrap responses in proper format (requires careful AST manipulation)
   - Report non-compliant routes

5. **Database Schema Validation:**
   - Run `npx prisma validate`
   - Parse output for errors/warnings
   - Check each model for required fields
   - Report schema issues

6. **Test Coverage Check:**
   - Run `npm run test:coverage -- src/features/`
   - Parse coverage report
   - Identify features below 80% threshold
   - Report coverage gaps

7. **Type Check:**
   - Run `npm run type-check` or `npx tsc --noEmit`
   - Parse TypeScript errors
   - Group errors by feature
   - Report type issues

8. **Generate Compliance Report:**

```markdown
# Architecture Compliance Report

Generated: [timestamp]

## Summary

- ✓ Directory Structure: PASS
- ✗ Client Components: 3 violations
- ✓ API Response Format: PASS
- ✗ Test Coverage: 2 features below threshold
- ✓ Type Safety: PASS

## Violations

### Client Component Directives

1. `src/features/auth/components/LoginForm.tsx`
   - Missing "use client" directive
   - Uses: useState, useEffect
   - **Fixed**: ✓ (if --fix enabled)

2. `src/features/dashboard/components/Chart.tsx`
   - Missing "use client" directive
   - Uses: useState
   - **Fixed**: ✓

### Test Coverage

1. `src/features/products/`
   - Coverage: 65%
   - Required: 80%
   - Missing tests for: ProductService.delete()

2. `src/features/orders/`
   - Coverage: 72%
   - Required: 80%
   - Missing tests for: OrderCalculator

## Recommendations

1. Add tests to low-coverage features
2. Review API error handling patterns
3. Consider adding integration tests

## Next Steps

- Fix remaining violations manually
- Run: `npm run test -- products orders`
- Re-run verification: `/verify-arch`
```

## Auto-Fix Capabilities

The `--fix` flag will automatically fix:

1. **Missing "use client" directives:**
   - Add to first line of affected component files
   - Preserve existing imports and code

2. **Directory structure:**
   - Create missing required directories
   - Move misplaced files to correct locations (with confirmation)

3. **Simple formatting issues:**
   - File naming conventions (rename files to proper case)

## Usage Examples

```bash
# Verify compliance only (no fixes)
/verify-arch

# Verify and auto-fix violations
/verify-arch --fix

# Check specific feature
# (Note: implement feature-specific check if needed)
/verify-arch products
```

## Output Format

Return a structured report with:
- Summary table showing pass/fail for each check
- Detailed violations list with file paths and line numbers
- Fix status (if --fix enabled)
- Actionable recommendations
- Commands to run for manual fixes

## Edge Cases to Handle

- Features in progress (may not have all directories yet)
- Third-party component libraries that require "use client"
- Test files in non-standard locations
- Custom API response formats (check for explicit opt-out comments)
- Monorepo structures with multiple Next.js apps

## Notes

- This command is safe to run anytime (read-only unless --fix specified)
- Can be run in CI/CD pipeline for automated checks
- Integrates with pre-commit hooks
- Results can be cached for faster subsequent runs
