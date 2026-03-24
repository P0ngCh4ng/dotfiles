# ClaudeCode Project Governance Template System

Complete guide for using the project governance template system.

## 📋 Overview

This template system provides ready-to-use architecture governance for your projects:

- **Next.js**: Feature-based architecture with Server/Client component validation
- **Express**: MVC pattern with service layer enforcement
- **Generic**: Universal code quality standards

## 🚀 Quick Start

### For New Projects

```bash
# Navigate to your project
cd my-new-project

# Initialize with template
/init-project nextjs    # or express, or generic

# Start coding!
```

**Time:** 5 minutes
**Result:** Complete architecture governance setup

### For Existing Projects

```bash
# Navigate to existing project
cd my-existing-project

# Analyze and auto-generate
/analyze-and-init

# Customize generated files
vim CLAUDE.md
```

**Time:** 2-3 minutes
**Result:** Tailored governance based on your code

## 📂 What Gets Created

### All Templates Include

```
your-project/
├── CLAUDE.md                    # Architecture rules (auto-loaded by Claude)
├── docs/
│   ├── ARCHITECTURE.md          # System design documentation
│   ├── API_SPEC.md             # API standards and conventions
│   ├── DATA_SCHEMA.md          # Database design patterns
│   └── COMMON_MISTAKES.md      # Mistake catalog with solutions
└── .claude/
    ├── agents/
    │   └── architecture-enforcer.md  # Automatic validation agent
    ├── commands/
    │   └── verify-arch.md       # Manual verification command
    └── hooks/
        ├── pre-commit           # Git pre-commit validation
        └── user-prompt-submit-hook.sh  # Prompt reminders
```

### Next.js Specific

```
.claude/commands/
└── scaffold-feature.md          # Generate complete feature structure
```

**Features:**
- Server/Client component validation
- Feature-based directory structure
- API response format checking
- Prisma schema management

### Express Specific

```
.claude/commands/
└── scaffold-endpoint.md         # Generate CRUD endpoint
```

**Features:**
- MVC layer separation
- Async error handling validation
- Service layer enforcement
- Request/response envelope

### Generic Specific

```
.claude/commands/
└── verify-quality.md            # General code quality check
```

**Features:**
- Universal clean code principles
- Documentation standards
- Test coverage requirements
- Framework-agnostic patterns

## 🎯 Usage Workflows

### Workflow 1: Starting a New Next.js Project

```bash
# 1. Create project
npx create-next-app@latest my-app --typescript --app --tailwind

# 2. Navigate to project
cd my-app

# 3. Initialize governance
/init-project nextjs

# 4. Verify setup
/verify-arch

# 5. Create first feature
/scaffold-feature users

# 6. Start coding!
```

### Workflow 2: Adding Governance to Existing Project

```bash
# 1. Navigate to project
cd existing-project

# 2. Auto-analyze and generate
/analyze-and-init

# 3. Review generated files
cat CLAUDE.md
cat docs/ARCHITECTURE.md

# 4. Customize for your project
vim CLAUDE.md

# 5. Verify existing code
/verify-arch

# 6. Fix violations
/verify-arch --fix
```

### Workflow 3: Team Onboarding

```bash
# 1. New team member clones repo
git clone repo-url
cd repo

# 2. Read project rules (auto-loaded)
cat CLAUDE.md

# 3. Read architecture docs
cat docs/ARCHITECTURE.md

# 4. Verify environment
/verify-arch

# 5. Create first feature
/scaffold-feature my-feature

# Claude will enforce rules automatically!
```

## 🔧 Commands Reference

### /init-project [type]

Initialize project with template.

```bash
# Available types
/init-project nextjs    # Next.js App Router
/init-project express   # Express.js REST API
/init-project generic   # Any project
```

**What it does:**
1. Copies template files
2. Customizes placeholders (project name, date)
3. Sets up Git hooks (optional)
4. Creates project documentation
5. Configures architecture enforcement

**Time:** 5 minutes

### /analyze-and-init

Auto-analyze codebase and generate governance.

```bash
/analyze-and-init                # Auto-detect framework
/analyze-and-init --framework=nextjs  # Force framework
/analyze-and-init --dry-run     # Preview without writing
```

**What it does:**
1. Detects framework and patterns
2. Analyzes directory structure
3. Identifies naming conventions
4. Generates tailored CLAUDE.md
5. Creates custom documentation
6. Extracts code examples

**Time:** 2-3 minutes

### /verify-arch

Verify architecture compliance.

```bash
/verify-arch           # Check all
/verify-arch --fix     # Auto-fix issues
```

**Checks:**
- Directory structure
- Naming conventions
- API response formats
- Component directives (Next.js)
- Layer separation (Express)
- Type safety
- Test coverage

### /scaffold-feature [name] (Next.js)

Generate complete feature structure.

```bash
/scaffold-feature users
/scaffold-feature user-profile
```

**Creates:**
- `src/features/[name]/api/` - API logic
- `src/features/[name]/components/` - UI components
- `src/features/[name]/hooks/` - React hooks
- `src/features/[name]/types/` - TypeScript types
- `src/features/[name]/__tests__/` - Tests

### /scaffold-endpoint [name] (Express)

Generate CRUD endpoint.

```bash
/scaffold-endpoint users
/scaffold-endpoint products
```

**Creates:**
- `src/routes/[name].route.ts` - Route definitions
- `src/controllers/[name].controller.ts` - Request handlers
- `src/services/[name].service.ts` - Business logic
- `src/models/[name].model.ts` - Data model
- `src/validators/[name].validator.ts` - Input validation

### /verify-quality (Generic)

Verify general code quality.

```bash
/verify-quality
```

**Checks:**
- Naming conventions
- Code comments
- Test coverage
- Documentation
- Error handling
- Security issues

## 📚 Customization Guide

### Customizing CLAUDE.md

```markdown
# Add project-specific rules

## Custom Rules

### Our Team's Conventions
- Always use absolute imports
- Prefix private methods with _
- Use Zod for validation

### Custom Verification
```bash
# Check for absolute imports
grep -r "from '\\.\\." src/
```
```

### Adding Custom Checks

Edit `.claude/agents/architecture-enforcer.md`:

```markdown
## Custom Validation

### Check for Absolute Imports
```bash
# Find relative imports
find src -name "*.ts" -exec grep -l "from '\\.\\." {} \;
```

If found:
- Warn: "Use absolute imports (@/...)"
- Auto-fix: Convert to absolute paths
```

### Customizing Templates

Create your own template variant:

```bash
# 1. Copy existing template
cp -r ~/.claude/templates/nextjs ~/.claude/templates/my-nextjs

# 2. Customize files
vim ~/.claude/templates/my-nextjs/CLAUDE.md.template

# 3. Use custom template
/init-project my-nextjs
```

## 🎓 Best Practices

### 1. Start Early

Add governance BEFORE writing code:
```bash
# ✅ Good
create-next-app my-app
cd my-app
/init-project nextjs
# Now start coding

# ❌ Bad
# Write 10k lines of code
# Then try to add governance
```

### 2. Customize Incrementally

Don't try to create perfect rules upfront:
```bash
# Week 1: Use default template
/init-project nextjs

# Week 2: Add team conventions
vim CLAUDE.md

# Week 3: Add common mistakes
vim docs/COMMON_MISTAKES.md

# Month 2: Create custom template
```

### 3. Update COMMON_MISTAKES.md

When you find a mistake:
```bash
# 1. Add to catalog
vim docs/COMMON_MISTAKES.md

# 2. Add detection script
vim .claude/scripts/detect-new-mistake.sh

# 3. Update pre-commit hook
vim .husky/pre-commit
```

### 4. Use Progressive Disclosure

Keep CLAUDE.md concise (150-200 lines):
```markdown
# CLAUDE.md (concise)
## API Rules
- Use standard format
- See docs/API_SPEC.md for details

# docs/API_SPEC.md (detailed)
[30 pages of API documentation]
```

### 5. Automate Enforcement

Rely on automation, not memory:
```bash
# ✅ Automated
- Pre-commit hook checks structure
- CI/CD runs /verify-arch
- Agent warns before violations

# ❌ Manual
- "Remember to follow the rules"
- "Check the docs"
```

## 🔍 Troubleshooting

### Templates Not Found

```bash
# Check template installation
ls ~/.claude/templates/

# Expected output:
# nextjs/
# express/
# generic/

# If missing, templates need to be created
```

### Permission Denied on Hooks

```bash
# Make hooks executable
chmod +x .claude/hooks/*
chmod +x .husky/pre-commit
```

### CLAUDE.md Not Loading

```bash
# CLAUDE.md must be in project root
ls CLAUDE.md

# If in subdirectory, move to root
mv docs/CLAUDE.md ./
```

### Placeholders Not Replaced

```bash
# Check for remaining placeholders
grep -r "{{" CLAUDE.md docs/

# Manually replace
perl -i -pe 's/\{\{PROJECT_NAME\}\}/my-project/g' CLAUDE.md
```

### Pre-commit Hook Not Running

```bash
# Check hook exists
ls .husky/pre-commit

# Make executable
chmod +x .husky/pre-commit

# Test manually
.husky/pre-commit
```

### Verify Command Not Working

```bash
# Check command exists
ls .claude/commands/verify-arch.md

# If missing, re-run init
/init-project nextjs
```

## 📊 Measuring Success

### Week 1
- [ ] Template installed
- [ ] CLAUDE.md customized
- [ ] Team reviewed docs

### Month 1
- [ ] 5+ entries in COMMON_MISTAKES.md
- [ ] Pre-commit hook catching violations
- [ ] 90%+ architecture compliance

### Month 3
- [ ] Custom template created
- [ ] Team onboarding < 1 day
- [ ] Design review time reduced 50%

## 💡 Tips

### For Solo Developers
- Start with `generic` template
- Add rules as you find patterns
- Use `/analyze-and-init` for quick setup

### For Small Teams (2-5)
- Use `nextjs` or `express` template
- Weekly review of COMMON_MISTAKES.md
- Customize pre-commit hooks

### For Large Teams (6+)
- Create custom template per project type
- Centralize templates in team repo
- CI/CD integration required
- Monthly template updates

## 🔗 Related Documentation

- **CLAUDE.md Spec**: https://docs.claude.com/claude-md
- **Architecture Patterns**: See `docs/ARCHITECTURE.md` in templates
- **Agent Development**: `~/.claude/agents/README.md`

## 🆘 Getting Help

### Check Existing Issues
```bash
# Search for similar problems
grep -r "your issue" ~/.claude/docs/
```

### Debug Mode
```bash
# Run with verbose output
/init-project nextjs --verbose
/verify-arch --verbose
```

### Share Template
```bash
# Export your customized template
tar -czf my-template.tar.gz .claude/ docs/ CLAUDE.md

# Share with team
```

---

**Last Updated:** {{CREATION_DATE}}
**Version:** 1.0.0
**Maintainer:** Your Team
