---
command: init-project
description: Initialize project with architecture governance templates
arguments:
  - name: template_type
    required: true
    description: "Template type: nextjs, express, or generic"
---

# Project Initialization Command

Initialize a new project with comprehensive architecture governance setup from templates.

## Usage

```bash
/init-project nextjs
/init-project express
/init-project generic
```

## What This Does

1. **Detects project information** (name, existing structure)
2. **Copies template files** from `~/.claude/templates/[type]/`
3. **Customizes placeholders** ({{PROJECT_NAME}}, {{CREATION_DATE}}, etc.)
4. **Sets up Git hooks** (optional, if Git repository detected)
5. **Analyzes existing code** (if applicable)
6. **Generates summary** and next steps

## Implementation

### Step 1: Validate Template Type

```bash
TEMPLATE_TYPE="$1"

# Validate template type
if [[ ! "$TEMPLATE_TYPE" =~ ^(nextjs|express|generic)$ ]]; then
  echo "❌ Invalid template type: $TEMPLATE_TYPE"
  echo ""
  echo "Available templates:"
  echo "  - nextjs   : Next.js App Router projects"
  echo "  - express  : Express.js REST API projects"
  echo "  - generic  : Language/framework-agnostic"
  echo ""
  echo "Usage: /init-project [template_type]"
  exit 1
fi

TEMPLATE_DIR="$HOME/.claude/templates/$TEMPLATE_TYPE"

if [ ! -d "$TEMPLATE_DIR" ]; then
  echo "❌ Template directory not found: $TEMPLATE_DIR"
  echo ""
  echo "Please ensure templates are installed in ~/.claude/templates/"
  exit 1
fi

echo "✅ Using template: $TEMPLATE_TYPE"
echo ""
```

### Step 2: Detect Project Information

```bash
echo "📦 Detecting project information..."

# Get project name from package.json or directory
PROJECT_NAME=$(basename "$(pwd)")

if [ -f "package.json" ]; then
  if command -v jq &> /dev/null; then
    PKG_NAME=$(jq -r '.name // empty' package.json)
    [ -n "$PKG_NAME" ] && PROJECT_NAME="$PKG_NAME"
  fi
fi

echo "   Project name: $PROJECT_NAME"

# Get creation date
CREATION_DATE=$(date +%Y-%m-%d)
echo "   Date: $CREATION_DATE"

# Detect example feature (for Next.js)
EXAMPLE_FEATURE="example"
if [ "$TEMPLATE_TYPE" = "nextjs" ]; then
  if [ -d "src/features" ]; then
    FIRST_FEATURE=$(find src/features -mindepth 1 -maxdepth 1 -type d | head -1 | xargs basename)
    [ -n "$FIRST_FEATURE" ] && EXAMPLE_FEATURE="$FIRST_FEATURE"
  fi
  echo "   Example feature: $EXAMPLE_FEATURE"
fi

# Detect production URL
PRODUCTION_URL="api.${PROJECT_NAME}.com"
echo "   Production URL: $PRODUCTION_URL"

echo ""
```

### Step 3: Copy Template Files

```bash
echo "📂 Copying template files..."

# Check for existing files
if [ -f "CLAUDE.md" ]; then
  echo "⚠️  CLAUDE.md already exists!"
  echo "   Backup existing file? (y/n)"
  read -r response
  if [ "$response" = "y" ]; then
    cp CLAUDE.md "CLAUDE.md.backup.$(date +%Y%m%d_%H%M%S)"
    echo "   ✅ Backed up to CLAUDE.md.backup.*"
  else
    echo "   ⚠️  Skipping CLAUDE.md"
  fi
fi

# Copy CLAUDE.md
if [ -f "$TEMPLATE_DIR/CLAUDE.md.template" ]; then
  cp "$TEMPLATE_DIR/CLAUDE.md.template" ./CLAUDE.md
  echo "   ✅ CLAUDE.md"
fi

# Copy docs/
mkdir -p docs
if [ -d "$TEMPLATE_DIR/docs" ]; then
  cp -r "$TEMPLATE_DIR/docs/"* ./docs/ 2>/dev/null || true
  echo "   ✅ docs/"
fi

# Copy .claude/ configs (project-level)
mkdir -p .claude/{agents,commands,hooks}

if [ -d "$TEMPLATE_DIR/agents" ]; then
  cp -r "$TEMPLATE_DIR/agents/"* ./.claude/agents/ 2>/dev/null || true
  echo "   ✅ .claude/agents/"
fi

if [ -d "$TEMPLATE_DIR/commands" ]; then
  cp -r "$TEMPLATE_DIR/commands/"* ./.claude/commands/ 2>/dev/null || true
  echo "   ✅ .claude/commands/"
fi

if [ -d "$TEMPLATE_DIR/hooks" ]; then
  cp -r "$TEMPLATE_DIR/hooks/"* ./.claude/hooks/ 2>/dev/null || true
  # Make hooks executable
  chmod +x .claude/hooks/* 2>/dev/null || true
  echo "   ✅ .claude/hooks/"
fi

echo ""
```

### Step 4: Customize Placeholders

```bash
echo "✏️  Customizing templates..."

# Function to replace placeholders in a file
customize_file() {
  local file=$1

  # Skip binary files
  if file "$file" | grep -q text; then
    # Use perl for cross-platform compatibility
    perl -i -pe "s/\{\{PROJECT_NAME\}\}/$PROJECT_NAME/g" "$file"
    perl -i -pe "s/\{\{CREATION_DATE\}\}/$CREATION_DATE/g" "$file"
    perl -i -pe "s/\{\{EXAMPLE_FEATURE\}\}/$EXAMPLE_FEATURE/g" "$file"
    perl -i -pe "s/\{\{PRODUCTION_URL\}\}/$PRODUCTION_URL/g" "$file"
  fi
}

# Find and customize all .md files
find . -name "*.md" -type f | while read -r file; do
  customize_file "$file"
  echo "   ✅ $(basename "$file")"
done

# Customize hook scripts
find .claude/hooks -type f 2>/dev/null | while read -r file; do
  customize_file "$file"
done

echo ""
```

### Step 5: Setup Git Hooks (Optional)

```bash
if [ -d ".git" ]; then
  echo "🔧 Git repository detected. Setup Git hooks? (y/n)"
  read -r response

  if [ "$response" = "y" ]; then
    echo "   Setting up Git hooks..."

    # Check if husky is already installed
    if [ -f "package.json" ]; then
      if ! grep -q "husky" package.json 2>/dev/null; then
        echo "   📦 Installing husky..."
        npm install --save-dev husky
        npx husky init
      fi

      # Copy pre-commit hook
      if [ -f ".claude/hooks/pre-commit" ]; then
        mkdir -p .husky
        cp .claude/hooks/pre-commit .husky/pre-commit
        chmod +x .husky/pre-commit
        echo "   ✅ Pre-commit hook configured"
      fi

      # Copy user-prompt-submit-hook if it exists
      if [ -f ".claude/hooks/user-prompt-submit-hook.sh" ]; then
        # This should be copied to global Claude config, not project
        echo "   💡 To enable user-prompt-submit hook globally:"
        echo "      cp .claude/hooks/user-prompt-submit-hook.sh ~/.claude/hooks/"
      fi
    else
      echo "   ⚠️  No package.json found. Skipping husky setup."
      echo "   💡 You can manually copy hooks from .claude/hooks/ to .git/hooks/"
    fi

    echo ""
  fi
fi
```

### Step 6: Analyze Existing Code (If Applicable)

```bash
echo "📊 Analyzing existing code structure..."

if [ "$TEMPLATE_TYPE" = "nextjs" ] && [ -d "src" ]; then
  echo ""
  echo "   Current structure:"
  find src -type d -maxdepth 3 2>/dev/null | head -20 | sed 's/^/   /'
  echo ""
  echo "   ⚠️  Review CLAUDE.md and adjust rules based on existing code"
  echo ""
elif [ "$TEMPLATE_TYPE" = "express" ] && [ -d "src" ]; then
  echo ""
  echo "   Current structure:"
  find src -type d -maxdepth 2 2>/dev/null | sed 's/^/   /'
  echo ""
  echo "   ⚠️  Ensure your structure matches the MVC pattern in docs/ARCHITECTURE.md"
  echo ""
elif [ -d "src" ] || [ -d "lib" ]; then
  echo ""
  echo "   Code detected. Consider customizing:"
  echo "   - CLAUDE.md (architecture rules)"
  echo "   - docs/ARCHITECTURE.md (system design)"
  echo ""
fi
```

### Step 7: Summary and Next Steps

```bash
cat << EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Project Initialized: $PROJECT_NAME
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📁 Created Files:
   - CLAUDE.md                           (project rules)
   - docs/ARCHITECTURE.md                (system design)
   - docs/API_SPEC.md                    (API standards)
   - docs/DATA_SCHEMA.md                 (database design)
   - docs/COMMON_MISTAKES.md             (mistake catalog)
   - .claude/agents/architecture-enforcer.md
   - .claude/commands/verify-arch.md
EOF

if [ "$TEMPLATE_TYPE" = "nextjs" ]; then
  echo "   - .claude/commands/scaffold-feature.md"
elif [ "$TEMPLATE_TYPE" = "express" ]; then
  echo "   - .claude/commands/scaffold-endpoint.md"
fi

cat << EOF

🚀 Next Steps:

   1. Review and customize CLAUDE.md
      vim CLAUDE.md

   2. Update docs/ARCHITECTURE.md with project-specific details
      vim docs/ARCHITECTURE.md

   3. Test the setup
EOF

if [ "$TEMPLATE_TYPE" = "nextjs" ]; then
  echo "      /verify-arch"
  echo "      /scaffold-feature test-feature"
elif [ "$TEMPLATE_TYPE" = "express" ]; then
  echo "      /verify-arch"
  echo "      /scaffold-endpoint users"
else
  echo "      /verify-quality"
fi

cat << EOF

   4. Start coding with architecture governance!

📚 Documentation:
   - Architecture rules: CLAUDE.md
   - Detailed design: docs/ARCHITECTURE.md
   - API standards: docs/API_SPEC.md
   - Common mistakes: docs/COMMON_MISTAKES.md

💡 Tips:
   - CLAUDE.md is loaded automatically in every Claude session
   - Use /verify-arch frequently to catch violations early
   - Update docs/COMMON_MISTAKES.md when you find new patterns
   - Customize templates to fit your team's needs

Happy coding! 🎉

EOF
```

## Template-Specific Features

### Next.js
- Feature-based directory structure enforcement
- Server/Client component validation
- API response format checking
- Prisma schema management

### Express
- MVC layer separation enforcement
- Async error handling validation
- Response envelope standardization
- Middleware pattern checking

### Generic
- Universal code quality checks
- Documentation completeness
- Test coverage requirements
- Clean code principles

## Troubleshooting

### Template not found
```bash
# Check if templates exist
ls -la ~/.claude/templates/

# If missing, templates need to be created first
```

### Permission denied on hooks
```bash
# Make hooks executable
chmod +x .claude/hooks/*
chmod +x .husky/pre-commit
```

### Placeholder not replaced
```bash
# Manually replace in specific file
perl -i -pe 's/\{\{PROJECT_NAME\}\}/your-project-name/g' CLAUDE.md
```

## Advanced Usage

### Initialize with custom project name
```bash
# Set PROJECT_NAME environment variable
PROJECT_NAME="my-custom-name" /init-project nextjs
```

### Dry run (preview changes)
```bash
# Preview what would be copied
ls -R ~/.claude/templates/nextjs/
```

### Re-initialize (update templates)
```bash
# Backup existing files first
cp CLAUDE.md CLAUDE.md.backup

# Then re-run
/init-project nextjs
```
