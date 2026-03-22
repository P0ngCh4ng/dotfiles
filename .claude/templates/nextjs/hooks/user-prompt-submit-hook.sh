#!/bin/bash
# user-prompt-submit-hook.sh
# Detects keywords in user prompts and shows relevant reminders

USER_PROMPT="$1"

# Convert to lowercase for case-insensitive matching
PROMPT_LOWER=$(echo "$USER_PROMPT" | tr '[:upper:]' '[:lower:]')

# Color codes for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print colored output
print_header() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${GREEN}ℹ️  $1${NC}"
}

print_command() {
    echo -e "${CYAN}  → $1${NC}"
}

# Track if any reminders were shown
SHOWED_REMINDER=false

# General reminders for any file creation/modification
if [[ "$PROMPT_LOWER" =~ (create|add|new|make|update|modify|edit|change) ]]; then
    print_header "📋 General Reminders"
    print_info "Always check project CLAUDE.md for architecture patterns"
    print_command "cat CLAUDE.md"
    print_info "Verify architecture compliance before starting"
    print_command "/verify-arch"
    echo ""
    SHOWED_REMINDER=true
fi

# Component creation detection
if [[ "$PROMPT_LOWER" =~ (component|react|tsx|jsx) ]] && [[ "$PROMPT_LOWER" =~ (create|new|add|make) ]]; then
    print_header "🧩 Component Creation Checklist"
    print_warning "Remember:"
    echo "  □ Check if component should be Client or Server Component"
    echo "  □ Server Components are DEFAULT (no 'use client' directive)"
    echo "  □ Only add 'use client' if component uses:"
    echo "    - useState, useEffect, or other React hooks"
    echo "    - Browser APIs (window, document, etc.)"
    echo "    - Event handlers (onClick, onChange, etc.)"
    echo "  □ Place in correct directory:"
    echo "    - app/components/ui/ for UI components"
    echo "    - app/components/features/ for feature-specific components"
    echo "  □ Use TypeScript interfaces for props"
    echo "  □ Add proper error boundaries if needed"
    echo ""
    print_info "Helpful commands:"
    print_command "ls app/components/ui/     # Check existing UI components"
    print_command "ls app/components/features/ # Check feature components"
    echo ""
    SHOWED_REMINDER=true
fi

# API route creation detection
if [[ "$PROMPT_LOWER" =~ (api|route|endpoint) ]] && [[ "$PROMPT_LOWER" =~ (create|new|add|make) ]]; then
    print_header "🔌 API Route Creation Checklist"
    print_warning "Remember:"
    echo "  □ API routes go in app/api/ directory"
    echo "  □ Use route.ts (NOT route.tsx)"
    echo "  □ Export named functions: GET, POST, PUT, DELETE, PATCH"
    echo "  □ Always return NextResponse with proper status codes"
    echo "  □ Use consistent response format:"
    echo "    Success: { success: true, data: {...} }"
    echo "    Error: { success: false, error: 'message' }"
    echo "  □ Add proper error handling with try-catch"
    echo "  □ Validate input data"
    echo "  □ Add TypeScript types for request/response"
    echo ""
    print_info "Helpful commands:"
    print_command "ls app/api/               # Check existing API routes"
    print_command "cat app/api/*/route.ts    # Review existing patterns"
    echo ""
    SHOWED_REMINDER=true
fi

# Database/Prisma detection
if [[ "$PROMPT_LOWER" =~ (database|prisma|schema|model|migration) ]]; then
    print_header "🗄️  Database/Prisma Checklist"
    print_warning "Remember:"
    echo "  □ Update prisma/schema.prisma for model changes"
    echo "  □ Run migrations after schema changes:"
    echo "    - npx prisma migrate dev (development)"
    echo "    - npx prisma migrate deploy (production)"
    echo "  □ Regenerate Prisma Client after schema changes"
    echo "  □ Use Prisma Client from lib/prisma.ts"
    echo "  □ Add proper indexes for performance"
    echo "  □ Use transactions for related operations"
    echo "  □ Handle unique constraint violations"
    echo ""
    print_info "Helpful commands:"
    print_command "npx prisma studio            # Open database GUI"
    print_command "npx prisma migrate dev       # Create & apply migration"
    print_command "npx prisma generate          # Regenerate Prisma Client"
    print_command "npx prisma db push           # Quick schema sync (dev only)"
    print_command "cat prisma/schema.prisma     # View current schema"
    echo ""
    SHOWED_REMINDER=true
fi

# Server Action detection
if [[ "$PROMPT_LOWER" =~ (action|server action|use server) ]]; then
    print_header "⚡ Server Action Checklist"
    print_warning "Remember:"
    echo "  □ Add 'use server' directive at top of file or function"
    echo "  □ Server actions can be in:"
    echo "    - app/actions/ directory (recommended)"
    echo "    - Inline in Server Components"
    echo "  □ Validate all inputs (never trust client data)"
    echo "  □ Return serializable data only (no functions, classes)"
    echo "  □ Handle errors gracefully"
    echo "  □ Use revalidatePath() or revalidateTag() to update cache"
    echo "  □ Consider using useFormStatus for loading states"
    echo ""
    print_info "Helpful commands:"
    print_command "ls app/actions/              # Check existing actions"
    print_command "grep -r 'use server' app/    # Find all server actions"
    echo ""
    SHOWED_REMINDER=true
fi

# Page/Layout creation detection
if [[ "$PROMPT_LOWER" =~ (page|layout|route) ]] && [[ "$PROMPT_LOWER" =~ (create|new|add|make) ]]; then
    print_header "📄 Page/Layout Creation Checklist"
    print_warning "Remember:"
    echo "  □ Pages: app/[route]/page.tsx"
    echo "  □ Layouts: app/[route]/layout.tsx"
    echo "  □ Use Server Components by default for pages/layouts"
    echo "  □ Implement proper loading.tsx for loading states"
    echo "  □ Implement proper error.tsx for error boundaries"
    echo "  □ Use metadata export for SEO"
    echo "  □ Consider dynamic routes: [id], [...slug], etc."
    echo "  □ Use generateStaticParams for static generation"
    echo ""
    print_info "Helpful commands:"
    print_command "ls -R app/                   # View route structure"
    print_command "find app/ -name 'page.tsx'   # Find all pages"
    print_command "find app/ -name 'layout.tsx' # Find all layouts"
    echo ""
    SHOWED_REMINDER=true
fi

# Testing detection
if [[ "$PROMPT_LOWER" =~ (test|spec|jest|testing) ]]; then
    print_header "🧪 Testing Checklist"
    print_warning "Remember:"
    echo "  □ Test files: *.test.ts, *.test.tsx, *.spec.ts"
    echo "  □ Test components in isolation"
    echo "  □ Test API routes with mock data"
    echo "  □ Test error cases, not just happy paths"
    echo "  □ Use proper mocks for external dependencies"
    echo "  □ Maintain test coverage above 80%"
    echo ""
    print_info "Helpful commands:"
    print_command "npm test                     # Run all tests"
    print_command "npm test -- --coverage       # Run with coverage"
    print_command "npm test -- --watch          # Watch mode"
    print_command "npm test -- ComponentName    # Test specific file"
    echo ""
    SHOWED_REMINDER=true
fi

# Environment variables detection
if [[ "$PROMPT_LOWER" =~ (env|environment|variable|config) ]]; then
    print_header "🔐 Environment Variables Checklist"
    print_warning "Remember:"
    echo "  □ Public vars: NEXT_PUBLIC_* (accessible in browser)"
    echo "  □ Server-only vars: No prefix (server-side only)"
    echo "  □ Update .env.example when adding new vars"
    echo "  □ Never commit .env to git"
    echo "  □ Document required env vars in README"
    echo "  □ Use process.env.VAR_NAME with proper validation"
    echo "  □ Add type checking for env vars"
    echo ""
    print_info "Helpful commands:"
    print_command "cat .env.example             # Check required env vars"
    print_command "grep -r 'process.env' .      # Find env var usage"
    echo ""
    SHOWED_REMINDER=true
fi

# File creation detection
if [[ "$PROMPT_LOWER" =~ (file|create file) ]] && [[ ! "$PROMPT_LOWER" =~ (component|api|page|layout) ]]; then
    print_header "📁 File Creation Checklist"
    print_warning "Remember:"
    echo "  □ Follow Next.js 14 App Router directory structure"
    echo "  □ Check if file should be in app/, lib/, or components/"
    echo "  □ Use TypeScript (.ts/.tsx) not JavaScript"
    echo "  □ Add proper imports and exports"
    echo "  □ Follow existing naming conventions"
    echo "  □ Update relevant index files if needed"
    echo ""
    print_info "Helpful commands:"
    print_command "tree -L 3 app/               # View app structure"
    print_command "ls lib/                      # Check utility files"
    echo ""
    SHOWED_REMINDER=true
fi

# Deployment detection
if [[ "$PROMPT_LOWER" =~ (deploy|deployment|vercel|production|build) ]]; then
    print_header "🚀 Deployment Checklist"
    print_warning "Remember:"
    echo "  □ Run production build locally first"
    echo "  □ Check for TypeScript errors"
    echo "  □ Run all tests"
    echo "  □ Verify environment variables are set"
    echo "  □ Check database migrations are applied"
    echo "  □ Review build output for warnings"
    echo "  □ Test in production-like environment"
    echo ""
    print_info "Helpful commands:"
    print_command "npm run build                # Production build"
    print_command "npm run start                # Test production build"
    print_command "npm run type-check           # TypeScript check"
    print_command "npm test                     # Run tests"
    echo ""
    SHOWED_REMINDER=true
fi

# Performance optimization detection
if [[ "$PROMPT_LOWER" =~ (performance|optimize|optimization|slow|speed) ]]; then
    print_header "⚡ Performance Optimization Checklist"
    print_warning "Remember:"
    echo "  □ Use Server Components for better performance"
    echo "  □ Implement dynamic imports for code splitting"
    echo "  □ Use next/image for optimized images"
    echo "  □ Use next/font for optimized fonts"
    echo "  □ Implement proper caching strategies"
    echo "  □ Use React.memo() for expensive components"
    echo "  □ Optimize database queries"
    echo "  □ Use streaming with Suspense"
    echo ""
    print_info "Helpful commands:"
    print_command "npm run build -- --profile   # Build with profiling"
    print_command "npm run analyze              # Analyze bundle size"
    echo ""
    SHOWED_REMINDER=true
fi

# If no specific reminders were shown, show generic best practices
if [ "$SHOWED_REMINDER" = false ]; then
    print_header "💡 General Best Practices"
    print_info "Before starting:"
    echo "  □ Review CLAUDE.md for project architecture"
    echo "  □ Check existing similar implementations"
    echo "  □ Plan the changes before coding"
    echo "  □ Write tests alongside implementation"
    echo "  □ Follow TypeScript best practices"
    echo "  □ Keep components small and focused"
    echo ""
    print_info "Helpful commands:"
    print_command "/verify-arch                 # Verify architecture compliance"
    print_command "cat CLAUDE.md                # Review project guidelines"
    print_command "npm run type-check           # Check TypeScript errors"
    echo ""
fi

# Exit successfully - this is informational only
exit 0
