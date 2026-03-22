---
command: analyze-and-init
description: Analyze existing codebase and auto-generate CLAUDE.md and architecture docs
---

# Analyze and Initialize Command

Automatically analyze your existing codebase and generate customized CLAUDE.md and documentation based on detected patterns.

## Usage

```bash
/analyze-and-init
/analyze-and-init --framework nextjs
/analyze-and-init --dry-run
```

## What This Does

1. **Analyzes codebase** (directory structure, file patterns, dependencies)
2. **Detects framework** (Next.js, Express, React, Vue, etc.)
3. **Identifies patterns** (architectural style, naming conventions)
4. **Generates CLAUDE.md** (tailored to your project)
5. **Creates documentation** (ARCHITECTURE.md, API_SPEC.md, etc.)
6. **Extracts examples** (from existing code for documentation)

## Implementation

### Step 1: Project Detection

```bash
echo "🔍 Analyzing codebase..."
echo ""

# Detect project type
detect_framework() {
  local framework="generic"

  # Check package.json
  if [ -f "package.json" ]; then
    if grep -q '"next"' package.json; then
      framework="nextjs"
    elif grep -q '"express"' package.json; then
      framework="express"
    elif grep -q '"react"' package.json; then
      framework="react"
    elif grep -q '"vue"' package.json; then
      framework="vue"
    fi
  fi

  # Check file patterns
  if [ -f "next.config.js" ] || [ -f "next.config.mjs" ]; then
    framework="nextjs"
  elif [ -d "src/routes" ] && grep -q "express" package.json 2>/dev/null; then
    framework="express"
  fi

  echo "$framework"
}

FRAMEWORK="${1#--framework=}"
if [ "$FRAMEWORK" = "/analyze-and-init" ] || [ -z "$FRAMEWORK" ]; then
  FRAMEWORK=$(detect_framework)
fi

echo "   Framework detected: $FRAMEWORK"

# Get project info
PROJECT_NAME=$(basename "$(pwd)")
if [ -f "package.json" ] && command -v jq &> /dev/null; then
  PKG_NAME=$(jq -r '.name // empty' package.json)
  [ -n "$PKG_NAME" ] && PROJECT_NAME="$PKG_NAME"
fi
echo "   Project name: $PROJECT_NAME"

# Analyze directory structure
echo ""
echo "   Analyzing directory structure..."
```

### Step 2: Analyze Directory Structure

Execute analysis based on framework:

**For Next.js:**
```bash
if [ "$FRAMEWORK" = "nextjs" ]; then
  # Check if using App Router or Pages Router
  ROUTER_TYPE="pages"
  if [ -d "app" ]; then
    ROUTER_TYPE="app"
  fi
  echo "   Next.js router: $ROUTER_TYPE"

  # Analyze features
  if [ -d "src/features" ]; then
    echo "   ✅ Feature-based structure detected"
    FEATURES=$(find src/features -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')
    echo "   Features found: $FEATURES"
  else
    echo "   ⚠️  No feature-based structure. Will recommend it."
  fi

  # Check for API routes
  if [ -d "app/api" ] || [ -d "pages/api" ]; then
    API_COUNT=$(find {app,pages}/api -name "route.ts" -o -name "*.ts" 2>/dev/null | wc -l | tr -d ' ')
    echo "   API routes: $API_COUNT"
  fi

  # Check for Prisma
  if [ -f "prisma/schema.prisma" ]; then
    echo "   ✅ Prisma detected"
    PRISMA=true
  fi
fi
```

**For Express:**
```bash
if [ "$FRAMEWORK" = "express" ]; then
  # Check for MVC structure
  MVC_SCORE=0
  [ -d "src/routes" ] && MVC_SCORE=$((MVC_SCORE + 1)) && echo "   ✅ Routes directory"
  [ -d "src/controllers" ] && MVC_SCORE=$((MVC_SCORE + 1)) && echo "   ✅ Controllers directory"
  [ -d "src/services" ] && MVC_SCORE=$((MVC_SCORE + 1)) && echo "   ✅ Services directory"
  [ -d "src/models" ] && MVC_SCORE=$((MVC_SCORE + 1)) && echo "   ✅ Models directory"

  if [ $MVC_SCORE -ge 3 ]; then
    echo "   ✅ MVC structure detected (score: $MVC_SCORE/4)"
  else
    echo "   ⚠️  Partial MVC structure. Will provide guidance."
  fi

  # Check database
  if grep -q "mongoose" package.json 2>/dev/null; then
    echo "   Database: MongoDB (Mongoose)"
  elif grep -q "prisma" package.json 2>/dev/null; then
    echo "   Database: Prisma"
  fi
fi
```

**For Generic:**
```bash
if [ "$FRAMEWORK" = "generic" ]; then
  # Analyze general structure
  echo "   Analyzing general code structure..."

  [ -d "src" ] && echo "   ✅ src/ directory"
  [ -d "test" ] || [ -d "tests" ] && echo "   ✅ Tests directory"
  [ -d "docs" ] && echo "   ✅ Docs directory"

  # Check for common patterns
  if [ -d "src/components" ]; then
    echo "   Pattern: Component-based"
  elif [ -d "src/modules" ]; then
    echo "   Pattern: Module-based"
  fi
fi
```

### Step 3: Analyze Code Patterns

```bash
echo ""
echo "   Analyzing code patterns..."

# Find naming conventions
if [ -d "src" ]; then
  PASCAL_COUNT=$(find src -name "*.ts" -o -name "*.tsx" 2>/dev/null | grep -E '[A-Z][a-z]+' | wc -l)
  KEBAB_COUNT=$(find src -name "*.ts" -o -name "*.tsx" 2>/dev/null | grep -E '[a-z]+-[a-z]+' | wc -l)

  if [ "$PASCAL_COUNT" -gt "$KEBAB_COUNT" ]; then
    NAMING_CONVENTION="PascalCase"
  else
    NAMING_CONVENTION="kebab-case"
  fi
  echo "   Naming convention: $NAMING_CONVENTION (detected)"
fi

# Check for TypeScript
if [ -f "tsconfig.json" ]; then
  echo "   ✅ TypeScript configured"
  TYPESCRIPT=true
fi

# Check for tests
TEST_FRAMEWORK="none"
if grep -q "vitest" package.json 2>/dev/null; then
  TEST_FRAMEWORK="Vitest"
elif grep -q "jest" package.json 2>/dev/null; then
  TEST_FRAMEWORK="Jest"
elif grep -q "mocha" package.json 2>/dev/null; then
  TEST_FRAMEWORK="Mocha"
fi
[ "$TEST_FRAMEWORK" != "none" ] && echo "   Testing: $TEST_FRAMEWORK"
```

### Step 4: Generate CLAUDE.md

```bash
echo ""
echo "✍️  Generating CLAUDE.md..."

# Use template as base if available
TEMPLATE_BASE="$HOME/.claude/templates/$FRAMEWORK/CLAUDE.md.template"
if [ -f "$TEMPLATE_BASE" ]; then
  echo "   Using $FRAMEWORK template as base"
  cp "$TEMPLATE_BASE" CLAUDE.md
else
  echo "   Generating from scratch"
  cat > CLAUDE.md << 'EOF'
# {{PROJECT_NAME}} - Project Rules

Generated automatically by /analyze-and-init on {{CREATION_DATE}}

## Overview

This file contains architecture rules and conventions for this project.
EOF
fi

# Customize with detected information
perl -i -pe "s/\{\{PROJECT_NAME\}\}/$PROJECT_NAME/g" CLAUDE.md
perl -i -pe "s/\{\{CREATION_DATE\}\}/$(date +%Y-%m-%d)/g" CLAUDE.md

# Add detected patterns
if [ "$FRAMEWORK" = "nextjs" ] && ! grep -q "feature-based" CLAUDE.md; then
  cat >> CLAUDE.md << 'EOF'

## Detected Patterns

### Directory Structure
Current structure analysis shows:
- Router type: {{ROUTER_TYPE}}
- Feature-based modules: {{FEATURE_COUNT}}
- API routes: {{API_COUNT}}

### Recommendations
- Use feature-based structure for better organization
- Keep Server Components as default
- Use "use client" only when necessary
EOF

  perl -i -pe "s/\{\{ROUTER_TYPE\}\}/$ROUTER_TYPE/g" CLAUDE.md
  perl -i -pe "s/\{\{FEATURE_COUNT\}\}/${FEATURES:-0}/g" CLAUDE.md
  perl -i -pe "s/\{\{API_COUNT\}\}/${API_COUNT:-0}/g" CLAUDE.md
fi

echo "   ✅ CLAUDE.md generated"
```

### Step 5: Generate Documentation

```bash
echo ""
echo "📚 Generating documentation..."

mkdir -p docs

# Generate ARCHITECTURE.md
if [ ! -f "docs/ARCHITECTURE.md" ]; then
  cat > docs/ARCHITECTURE.md << EOF
# $PROJECT_NAME - System Architecture

Generated: $(date +%Y-%m-%d)

## Overview

Framework: $FRAMEWORK
Language: ${TYPESCRIPT:+TypeScript}${TYPESCRIPT:-JavaScript}
Testing: $TEST_FRAMEWORK

## Current Structure

\`\`\`
$(find src -type d -maxdepth 2 2>/dev/null | head -20)
\`\`\`

## Detected Patterns

EOF

  if [ "$FRAMEWORK" = "nextjs" ]; then
    cat >> docs/ARCHITECTURE.md << 'EOF'
### Next.js App Router

This project uses Next.js App Router with:
- Server Components (default)
- Client Components (when interactivity needed)
- API Routes for backend logic

### Recommendations
- Use Server Components for data fetching
- Add "use client" only for interactive components
- Organize by features in src/features/
EOF
  elif [ "$FRAMEWORK" = "express" ]; then
    cat >> docs/ARCHITECTURE.md << 'EOF'
### Express MVC Pattern

Recommended structure:
- Routes: Handle HTTP requests
- Controllers: Request/response logic
- Services: Business logic
- Models: Data access

### Current Status
Review src/ directory and align with MVC pattern.
EOF
  fi

  echo "   ✅ docs/ARCHITECTURE.md"
fi

# Generate API_SPEC.md if API routes detected
if [ "$API_COUNT" -gt 0 ] || [ "$FRAMEWORK" = "express" ]; then
  if [ ! -f "docs/API_SPEC.md" ]; then
    TEMPLATE_API="$HOME/.claude/templates/$FRAMEWORK/docs/API_SPEC.md.template"
    if [ -f "$TEMPLATE_API" ]; then
      cp "$TEMPLATE_API" docs/API_SPEC.md
      perl -i -pe "s/\{\{PROJECT_NAME\}\}/$PROJECT_NAME/g" docs/API_SPEC.md
      echo "   ✅ docs/API_SPEC.md"
    fi
  fi
fi

# Generate DATA_SCHEMA.md if database detected
if [ "$PRISMA" = true ] || grep -q "mongoose\|prisma" package.json 2>/dev/null; then
  if [ ! -f "docs/DATA_SCHEMA.md" ]; then
    TEMPLATE_SCHEMA="$HOME/.claude/templates/$FRAMEWORK/docs/DATA_SCHEMA.md.template"
    if [ -f "$TEMPLATE_SCHEMA" ]; then
      cp "$TEMPLATE_SCHEMA" docs/DATA_SCHEMA.md
      perl -i -pe "s/\{\{PROJECT_NAME\}\}/$PROJECT_NAME/g" docs/DATA_SCHEMA.md
      echo "   ✅ docs/DATA_SCHEMA.md"
    fi
  fi
fi

# Copy COMMON_MISTAKES.md
if [ ! -f "docs/COMMON_MISTAKES.md" ]; then
  TEMPLATE_MISTAKES="$HOME/.claude/templates/$FRAMEWORK/docs/COMMON_MISTAKES.md.template"
  if [ -f "$TEMPLATE_MISTAKES" ]; then
    cp "$TEMPLATE_MISTAKES" docs/COMMON_MISTAKES.md
    perl -i -pe "s/\{\{PROJECT_NAME\}\}/$PROJECT_NAME/g" docs/COMMON_MISTAKES.md
    echo "   ✅ docs/COMMON_MISTAKES.md"
  fi
fi
```

### Step 6: Extract Code Examples

```bash
echo ""
echo "📝 Extracting code examples..."

# Find example API route
if [ "$FRAMEWORK" = "nextjs" ]; then
  EXAMPLE_API=$(find {app,pages}/api -name "route.ts" -o -name "*.ts" 2>/dev/null | head -1)
  if [ -n "$EXAMPLE_API" ]; then
    echo "   Example API found: $EXAMPLE_API"
    echo "   💡 Review this file and add similar patterns to docs/"
  fi
fi

# Find example component
EXAMPLE_COMPONENT=$(find src -name "*.tsx" 2>/dev/null | grep -i "component" | head -1)
if [ -n "$EXAMPLE_COMPONENT" ]; then
  echo "   Example component: $EXAMPLE_COMPONENT"
fi
```

### Step 7: Summary

```bash
cat << EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Analysis Complete: $PROJECT_NAME
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📊 Detected:
   Framework: $FRAMEWORK
   TypeScript: ${TYPESCRIPT:-No}
   Testing: $TEST_FRAMEWORK
   Naming: ${NAMING_CONVENTION:-mixed}

📁 Generated Files:
   - CLAUDE.md (architecture rules)
   - docs/ARCHITECTURE.md (system design)
EOF

[ -f "docs/API_SPEC.md" ] && echo "   - docs/API_SPEC.md (API standards)"
[ -f "docs/DATA_SCHEMA.md" ] && echo "   - docs/DATA_SCHEMA.md (database design)"
[ -f "docs/COMMON_MISTAKES.md" ] && echo "   - docs/COMMON_MISTAKES.md (mistake catalog)"

cat << EOF

🚀 Next Steps:

   1. Review generated CLAUDE.md
      vim CLAUDE.md

   2. Customize docs/ based on your project
      vim docs/ARCHITECTURE.md

   3. Add project-specific examples from your code

   4. Test the setup
EOF

if [ "$FRAMEWORK" = "nextjs" ]; then
  echo "      /verify-arch"
elif [ "$FRAMEWORK" = "express" ]; then
  echo "      /verify-arch"
else
  echo "      /verify-quality"
fi

cat << EOF

📚 Tips:
   - Generated files are based on detected patterns
   - Customize CLAUDE.md with project-specific rules
   - Update docs/ as your architecture evolves
   - Add real examples from your codebase

Happy coding! 🎉

EOF
```

## Options

### Dry Run
```bash
# Preview what would be generated without writing files
/analyze-and-init --dry-run
```

### Force Framework
```bash
# Override auto-detection
/analyze-and-init --framework=nextjs
/analyze-and-init --framework=express
```

### Verbose Output
```bash
# Show detailed analysis
/analyze-and-init --verbose
```

## What Gets Analyzed

### Directory Structure
- Presence of standard directories (src/, app/, pages/, etc.)
- Feature-based vs. layer-based organization
- Test directory structure

### Dependencies (package.json)
- Framework (Next.js, Express, React, etc.)
- Database (Prisma, Mongoose, etc.)
- Testing framework (Jest, Vitest, etc.)
- TypeScript usage

### Code Patterns
- Naming conventions (PascalCase, kebab-case, camelCase)
- Component patterns (Server/Client in Next.js)
- API structure (REST, GraphQL)
- Error handling patterns

### Configuration Files
- tsconfig.json → TypeScript settings
- next.config.js → Next.js configuration
- prisma/schema.prisma → Database schema

## Advantages Over /init-project

| Feature | /init-project | /analyze-and-init |
|---------|---------------|-------------------|
| Speed | Fast (copies templates) | Slower (analyzes first) |
| Accuracy | Generic | Tailored to your code |
| Use Case | New projects | Existing projects |
| Customization | Manual after | Automatic |
| Examples | Template examples | Your actual code |

## Troubleshooting

### Incorrect framework detected
```bash
# Force correct framework
/analyze-and-init --framework=nextjs
```

### Missing dependencies for analysis
```bash
# Install jq for JSON parsing
brew install jq  # macOS
apt install jq   # Linux
```

### Files not generated
```bash
# Check if templates exist
ls ~/.claude/templates/nextjs/

# Manually trigger with template
/init-project nextjs
```
