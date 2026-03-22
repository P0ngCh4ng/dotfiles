# Next.js Project Hooks

This directory contains hook scripts for Next.js 14 App Router projects to improve development workflow and code quality.

## Available Hooks

### 1. user-prompt-submit-hook.sh

**Purpose**: Detects keywords in user prompts and shows relevant reminders and checklists.

**Usage**: This hook is automatically triggered when you submit a prompt. It analyzes the content and displays:
- Context-aware reminders based on task type
- Relevant checklists (components, API routes, database, etc.)
- Helpful command suggestions
- Best practices and common pitfalls

**Detected Patterns**:
- Component creation (`create component`, `new React component`, etc.)
- API route creation (`create api`, `add endpoint`, etc.)
- Database/Prisma operations (`database`, `schema`, `migration`, etc.)
- Server Actions (`server action`, `use server`, etc.)
- Page/Layout creation (`create page`, `new layout`, etc.)
- Testing (`test`, `jest`, `spec`, etc.)
- Environment variables (`env`, `config`, etc.)
- Deployment (`deploy`, `build`, `production`, etc.)
- Performance optimization (`optimize`, `performance`, etc.)

**Example Output**:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔌 API Route Creation Checklist
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️  Remember:
  □ API routes go in app/api/ directory
  □ Use route.ts (NOT route.tsx)
  □ Export named functions: GET, POST, PUT, DELETE, PATCH
  □ Always return NextResponse with proper status codes
  ...
```

### 2. pre-commit

**Purpose**: Git pre-commit hook that validates code quality before allowing commits.

**Setup**:
```bash
# In your Next.js project
cp ~/.claude/templates/nextjs/hooks/pre-commit .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

**Validations Performed**:

1. **Directory Structure Validation**
   - Ensures API routes are named `route.ts`
   - Checks pages are named `page.tsx`
   - Validates components are in correct directories
   - Warns about CSS files in wrong locations

2. **Client Component Validation**
   - Detects missing `'use client'` directives
   - Warns about unnecessary `'use client'` usage
   - Checks for client-side features (hooks, event handlers, browser APIs)

3. **API Response Format Validation**
   - Ensures NextResponse is used
   - Validates standard response format: `{ success: true/false, data/error: ... }`
   - Checks for try-catch error handling
   - Verifies named exports (GET, POST, etc.)

4. **TypeScript Type Check**
   - Runs `npm run type-check`
   - Blocks commit on TypeScript errors

5. **Linting Check**
   - Runs `npm run lint`
   - Blocks commit on linting errors

6. **Test Execution**
   - Runs test suite
   - Blocks commit on test failures

**Example Output (Success)**:
```
╔════════════════════════════════════════════════════════════════╗
║                  ✓ VALIDATION PASSED ✓                        ║
╚════════════════════════════════════════════════════════════════╝
All checks passed. Proceeding with commit...
```

**Example Output (Failure)**:
```
╔════════════════════════════════════════════════════════════════╗
║                    ❌ COMMIT BLOCKED ❌                        ║
╚════════════════════════════════════════════════════════════════╝
Please fix the errors above before committing.
```

**Bypass Hook** (NOT RECOMMENDED):
```bash
git commit --no-verify
```

## Integration with Next.js Projects

### Recommended Setup

1. **Install pre-commit hook**:
```bash
cp ~/.claude/templates/nextjs/hooks/pre-commit .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

2. **Ensure package.json scripts**:
```json
{
  "scripts": {
    "type-check": "tsc --noEmit",
    "lint": "next lint",
    "test": "jest",
    "build": "next build"
  }
}
```

3. **Configure TypeScript**:
Ensure `tsconfig.json` exists with proper configuration.

4. **Configure ESLint**:
Ensure `.eslintrc.json` or `.eslintrc.js` exists.

## Customization

### Disable Specific Checks

Edit the pre-commit hook and comment out sections you don't need:

```bash
# Comment out test execution
# print_header "6. Running Tests"
# ...
```

### Add Custom Validations

Add new validation sections following the existing pattern:

```bash
# ============================================================================
# X. YOUR CUSTOM CHECK
# ============================================================================
print_header "X. Your Custom Check"

# Your validation logic here
if [ condition ]; then
    print_error "Your error message"
fi
```

### Adjust Severity Levels

Change `print_error` to `print_warning` for non-blocking warnings:

```bash
# This blocks commit
print_error "Critical issue"

# This shows warning but allows commit
print_warning "Non-critical issue"
```

## Best Practices

1. **Don't bypass the hook** unless absolutely necessary
2. **Fix issues promptly** rather than accumulating technical debt
3. **Run checks locally** before committing:
   ```bash
   npm run type-check
   npm run lint
   npm test
   npm run build
   ```
4. **Keep hooks updated** as project requirements change
5. **Document project-specific patterns** in CLAUDE.md

## Troubleshooting

### Hook not running
```bash
# Verify hook is executable
ls -l .git/hooks/pre-commit

# Make it executable if needed
chmod +x .git/hooks/pre-commit
```

### Tests failing in hook but passing locally
```bash
# Ensure same Node version
node --version

# Clear cache and reinstall
rm -rf node_modules package-lock.json
npm install
```

### TypeScript errors
```bash
# Run type check locally to see details
npm run type-check

# Check tsconfig.json configuration
cat tsconfig.json
```

## Contributing

To improve these hooks:

1. Test changes thoroughly
2. Document new features in this README
3. Keep backward compatibility
4. Add appropriate error messages
5. Follow existing code style

## License

These hooks are part of the dotfiles repository and follow the same license.
