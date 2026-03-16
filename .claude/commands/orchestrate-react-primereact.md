# Orchestrate - React+PrimeReact Full-Stack Workflow

Sequential agent workflow for React+PrimeReact frontend with backend API integration. Comprehensive development pipeline from planning to deployment.

## Usage

`/orchestrate-react [workflow-type] [task-description]`

## Stack Context

- **Frontend**: React 18+ (TypeScript, Hooks, Context API), PrimeReact UI components, React Router, Axios/Fetch
- **Backend**: Node.js/Express, Python/FastAPI, or any RESTful API backend
- **State Management**: React Context API, Zustand, or Redux Toolkit
- **Styling**: PrimeReact themes, CSS Modules, Styled Components, or Tailwind CSS
- **Testing**: Vitest/Jest, React Testing Library, Playwright for E2E

---

## Workflow Types

### feature
Full feature implementation workflow with React+PrimeReact:
```
planner -> ui-generator -> code-reviewer -> ui-reviewer -> ui-accessibility-checker
```

**Use Cases**:
- New React component with PrimeReact integration
- Complete feature with frontend + API integration
- Dashboard or data table implementation using PrimeReact DataTable
- Form creation with PrimeReact form components

**Example**: `/orchestrate-react feature "Create user management dashboard with PrimeReact DataTable and filtering"`

---

### ui-intensive
UI-focused workflow with comprehensive design validation:
```
ui-generator -> ui-layout-checker -> ui-responsive-checker -> ui-consistency-checker -> ui-decision-maker
```

**Use Cases**:
- PrimeReact component theming and customization
- Responsive layout implementation
- Multi-device compatibility validation
- Design system consistency checks

**Example**: `/orchestrate-react ui-intensive "Design product catalog with PrimeReact cards and responsive grid"`

---

### bugfix
Bug investigation and fix workflow:
```
planner -> code-reviewer -> ui-reviewer (if UI-related)
```

**Use Cases**:
- React component rendering issues
- PrimeReact component configuration problems
- State management bugs
- API integration errors

**Example**: `/orchestrate-react bugfix "Fix DataTable pagination not updating when filters change"`

---

### refactor
Safe refactoring workflow with quality gates:
```
planner -> code-reviewer -> ui-consistency-checker -> ui-accessibility-checker
```

**Use Cases**:
- Component structure reorganization
- State management migration (e.g., Context to Zustand)
- PrimeReact version upgrade
- TypeScript migration

**Example**: `/orchestrate-react refactor "Migrate class components to functional components with hooks"`

---

### accessibility
Accessibility-focused review and improvement:
```
ui-accessibility-checker -> ui-decision-maker -> code-reviewer
```

**Use Cases**:
- WCAG 2.1 compliance validation
- Keyboard navigation improvements
- Screen reader compatibility
- ARIA attributes validation

**Example**: `/orchestrate-react accessibility "Audit and fix accessibility issues in checkout form"`

---

### api-integration
API integration workflow with error handling:
```
planner -> code-reviewer -> ui-reviewer
```

**Use Cases**:
- RESTful API integration with React hooks
- GraphQL client setup
- API error handling and loading states
- Authentication and authorization flows

**Example**: `/orchestrate-react api-integration "Integrate user authentication API with React context"`

---

## Execution Pattern

For each agent in the workflow:

1. **Invoke agent** with React+PrimeReact specific context
2. **Collect output** as structured handoff document
3. **Pass to next agent** in chain with stack-specific guidelines
4. **Aggregate results** into final report with actionable recommendations

---

## React+PrimeReact Context Template

Before invoking any agent, gather and provide:

```markdown
## Stack Context
- React Version: 18.x
- PrimeReact Version: 10.x
- State Management: [Context API / Zustand / Redux Toolkit]
- Routing: React Router v6
- Build Tool: [Vite / Create React App / Next.js]
- TypeScript: [Yes/No]
- Styling Approach: [PrimeReact themes / CSS Modules / Styled Components / Tailwind]

## Project Structure
- Components: src/components/
- Pages/Views: src/pages/ or src/views/
- Hooks: src/hooks/
- Context/Store: src/context/ or src/store/
- API Services: src/services/ or src/api/
- Types: src/types/ (if TypeScript)
- Theme: src/theme/ or public/themes/

## Relevant Files
[List key files related to the task]

## PrimeReact Components Used
[List PrimeReact components: DataTable, Dialog, Button, Calendar, etc.]

## API Endpoints
[List relevant API endpoints if applicable]
```

---

## Handoff Document Format

Between agents, create handoff document with React specifics:

```markdown
## HANDOFF: [previous-agent] -> [next-agent]

### Context
[Summary of what was done]

### React Components Modified
| Component | Path | Changes |
|-----------|------|---------|
| UserTable | src/components/UserTable.tsx | Added filtering |

### PrimeReact Components Used
- DataTable (with pagination, sorting, filtering)
- Dialog (for user edit modal)
- Button (with severity variants)
- InputText (with validation)

### Hooks and State
- Custom hooks: useUsers, useDebounce
- Context: UserContext for global user state
- Local state: filter values, dialog visibility

### API Integration
- Endpoints: GET /api/users, POST /api/users
- Error handling: Toast messages via PrimeReact Toast
- Loading states: Skeleton component during fetch

### Files Modified
[List of files touched with line numbers]

### TypeScript Types
[New interfaces or type updates]

### Styling Changes
- PrimeReact theme customization
- CSS module updates
- Responsive breakpoints

### Open Questions
[Unresolved items for next agent]

### Recommendations for Next Agent
[Suggested next steps with React/PrimeReact focus]

### Testing Considerations
- Unit tests needed for custom hooks
- Component tests for user interactions
- E2E scenarios for complete user flows
```

---

## Example: Feature Workflow

```
/orchestrate-react feature "Add user management dashboard with PrimeReact DataTable"
```

Executes:

### 1. Planner Agent
**Input**: Feature requirement + stack context
**Actions**:
- Analyzes requirements
- Identifies React components needed
- Lists PrimeReact components to use (DataTable, Dialog, Button, etc.)
- Plans state management approach
- Defines API integration points
- Creates step-by-step implementation plan

**Output**: `HANDOFF: planner -> ui-generator`
```markdown
## Implementation Plan
1. Create UserManagementPage component
2. Setup UserContext for state management
3. Create useUsers custom hook for API calls
4. Implement UserTable component with PrimeReact DataTable
5. Add UserDialog component for create/edit
6. Configure pagination, sorting, and filtering
7. Add error handling with Toast notifications
8. Implement loading states with Skeleton
```

---

### 2. UI Generator Agent
**Input**: Implementation plan + design requirements
**Actions**:
- Generates React component structure
- Implements PrimeReact component integration
- Creates TypeScript interfaces (if applicable)
- Applies PrimeReact theming
- Implements responsive layout
- Adds proper prop types and validation

**Output**: `HANDOFF: ui-generator -> code-reviewer`
```markdown
## Generated Components
- UserManagementPage.tsx (main page component)
- UserTable.tsx (DataTable wrapper)
- UserDialog.tsx (create/edit form)
- useUsers.ts (custom hook)

## PrimeReact Components Configured
- DataTable with lazy loading and pagination
- Dialog with form validation
- Button with severity styling
- InputText with error states
- Toast for notifications
```

---

### 3. Code Reviewer Agent
**Input**: Generated code + React best practices
**Actions**:
- Reviews React hooks usage (useEffect dependencies, custom hooks)
- Checks component composition and reusability
- Validates TypeScript types and interfaces
- Reviews state management patterns
- Checks for performance issues (useMemo, useCallback)
- Validates error handling and edge cases
- Ensures proper prop drilling or context usage

**Output**: `HANDOFF: code-reviewer -> ui-reviewer`
```markdown
## Code Quality Issues Found
1. Missing useCallback for event handlers
2. DataTable lacks error boundary
3. Custom hook missing loading state handling
4. TypeScript interface incomplete for API response

## Recommendations
- Wrap event handlers in useCallback to prevent re-renders
- Add ErrorBoundary component around DataTable
- Extend useUsers hook with error and loading states
- Update User interface with all API fields
```

---

### 4. UI Reviewer Agent
**Input**: Code + handoff from code-reviewer
**Actions**:
- Launches Playwright browser automation
- Tests PrimeReact component rendering
- Validates UI interactions (clicks, form inputs)
- Checks responsive behavior
- Tests DataTable features (pagination, sorting, filtering)
- Validates Dialog open/close behavior
- Captures screenshots for visual regression

**Output**: `HANDOFF: ui-reviewer -> ui-accessibility-checker`
```markdown
## UI Testing Results
✅ DataTable renders correctly with data
✅ Pagination controls working
✅ Sorting functionality operational
❌ Filter input not clearing after reset
✅ Dialog opens and closes properly
⚠️  Mobile layout needs adjustment for table

## Visual Issues
- DataTable overflows on mobile screens
- Dialog close button too small on touch devices
```

---

### 5. UI Accessibility Checker Agent
**Input**: Rendered components + WCAG guidelines
**Actions**:
- Validates WCAG 2.1 Level AA compliance
- Checks keyboard navigation (Tab, Enter, Escape)
- Tests screen reader compatibility
- Validates ARIA attributes on PrimeReact components
- Checks color contrast ratios
- Tests focus management in Dialog

**Output**: Final Report
```markdown
## Accessibility Audit Results
✅ All interactive elements keyboard accessible
✅ PrimeReact components have proper ARIA labels
❌ Color contrast ratio fails on disabled buttons (3.2:1, needs 4.5:1)
⚠️  Dialog lacks focus trap (focus can escape to background)
❌ DataTable filter inputs missing aria-label

## Recommendations
1. Update button disabled color in theme
2. Implement focus trap in Dialog component
3. Add aria-label to filter InputText components
4. Add aria-live region for Toast notifications
```

---

## Final Report Format

```
ORCHESTRATION REPORT - REACT+PRIMEREACT
========================================
Workflow: feature
Task: Add user management dashboard with PrimeReact DataTable
Stack: React 18.2, PrimeReact 10.5, TypeScript, Vite
Agents: planner -> ui-generator -> code-reviewer -> ui-reviewer -> ui-accessibility-checker

SUMMARY
-------
Successfully implemented user management dashboard with full CRUD operations.
Used PrimeReact DataTable with pagination, sorting, and filtering. Created
reusable custom hook for API integration. Identified 3 accessibility issues
and 1 responsive layout issue requiring fixes.

AGENT OUTPUTS
-------------
Planner: Generated 8-step implementation plan covering components, state,
         API integration, and error handling.

UI Generator: Created 4 React components with proper TypeScript typing and
              PrimeReact integration. Applied consistent theming.

Code Reviewer: Found 4 code quality issues related to hooks optimization,
               error handling, and TypeScript completeness. All addressable.

UI Reviewer: Validated 6 UI interaction scenarios. Found filter reset bug
             and mobile layout overflow issue.

Accessibility Checker: Identified 3 WCAG violations (color contrast, focus
                       management, ARIA labels). Provided specific fixes.

COMPONENTS CREATED
------------------
✅ src/pages/UserManagementPage.tsx (main page)
✅ src/components/UserTable.tsx (DataTable wrapper)
✅ src/components/UserDialog.tsx (create/edit form)
✅ src/hooks/useUsers.ts (API integration hook)
✅ src/types/User.ts (TypeScript interfaces)

PRIMEREACT COMPONENTS USED
---------------------------
- DataTable (pagination, sorting, filtering, lazy loading)
- Dialog (form modal)
- Button (primary, secondary, danger variants)
- InputText (with validation states)
- Toast (success/error notifications)
- Skeleton (loading states)

FILES CHANGED
-------------
Total: 8 files
- New files: 5
- Modified files: 3 (App.tsx, theme.css, api/userService.ts)

TEST COVERAGE
-------------
- Unit tests: useUsers hook (needed)
- Component tests: UserTable, UserDialog (needed)
- E2E tests: Full CRUD flow (recommended)

ACCESSIBILITY STATUS
--------------------
WCAG 2.1 Level: AA (Partial)
Issues Found: 3
- Color contrast on disabled buttons (HIGH)
- Dialog focus trap missing (MEDIUM)
- DataTable filter labels missing (MEDIUM)

RESPONSIVE STATUS
-----------------
Desktop (1920x1080): ✅ Passed
Tablet (768x1024): ✅ Passed
Mobile (375x667): ❌ Table overflow issue

RECOMMENDATION
--------------
🟡 NEEDS WORK

Required Fixes Before Merge:
1. Fix DataTable mobile overflow (add horizontal scroll or responsive columns)
2. Fix filter reset button functionality
3. Update disabled button color contrast ratio
4. Implement Dialog focus trap
5. Add aria-labels to filter inputs

Optional Improvements:
- Add unit tests for useUsers hook
- Add component tests for interactions
- Consider virtual scrolling for large datasets
- Add optimistic UI updates for better UX

Estimated Time to Fix: 2-3 hours

NEXT STEPS
----------
1. Address required accessibility fixes
2. Fix responsive layout for mobile
3. Fix filter reset bug
4. Add recommended unit tests
5. Re-run ui-reviewer and ui-accessibility-checker agents
6. Final code review before merge
```

---

## Parallel Execution

For independent checks, run agents in parallel:

```markdown
### Parallel Phase
Run simultaneously:
- code-reviewer (React code quality)
- ui-consistency-checker (PrimeReact theme consistency)
- ui-accessibility-checker (WCAG compliance)

### Merge Results
Combine outputs into single comprehensive report
```

---

## Arguments

$ARGUMENTS:
- `feature <description>` - Full feature workflow with UI and code review
- `ui-intensive <description>` - UI-focused workflow with design validation
- `bugfix <description>` - Bug fix workflow
- `refactor <description>` - Refactoring workflow with safety checks
- `accessibility <description>` - Accessibility audit and fixes
- `api-integration <description>` - API integration workflow
- `custom <agents> <description>` - Custom agent sequence

---

## Custom Workflow Example

```
/orchestrate-react custom "planner,ui-generator,ui-responsive-checker,code-reviewer" "Build responsive pricing page with PrimeReact cards"
```

This custom workflow focuses on responsive design by inserting `ui-responsive-checker` before final code review.

---

## React+PrimeReact Best Practices

### Component Structure
- Use functional components with hooks (no class components)
- Prefer composition over prop drilling
- Extract reusable logic into custom hooks
- Use TypeScript for type safety (strongly recommended)

### PrimeReact Integration
- Import components individually to reduce bundle size
- Use PrimeReact theme customization for consistent styling
- Leverage built-in accessibility features of PrimeReact components
- Use PrimeReact's responsive utilities (p-grid, p-col)

### State Management
- Use Context API for global state (auth, theme, user preferences)
- Use local state (useState) for component-specific data
- Consider Zustand or Redux Toolkit for complex state
- Use custom hooks to encapsulate state logic and API calls

### Performance
- Memoize expensive computations with useMemo
- Wrap event handlers in useCallback to prevent re-renders
- Use React.memo for components that render frequently
- Implement lazy loading for DataTable with large datasets
- Use code splitting with React.lazy and Suspense

### API Integration
- Create dedicated service layer for API calls (src/services/)
- Use custom hooks for API integration (useUsers, useProducts)
- Implement proper error handling and loading states
- Use React Query or SWR for advanced caching (optional)

### Styling
- Use PrimeReact themes as base (Lara, Material, Bootstrap)
- Customize theme variables in CSS for brand consistency
- Use CSS Modules or Styled Components for component-specific styles
- Ensure responsive design with PrimeReact's grid system

### Testing
- Write unit tests for custom hooks
- Use React Testing Library for component tests
- Use Playwright for E2E testing of user flows
- Test PrimeReact component interactions (DataTable sorting, Dialog forms)

---

## Tips

1. **Start with planner** for complex features - ensures proper architecture
2. **Always include code-reviewer** for React hooks and performance issues
3. **Use ui-reviewer** to validate PrimeReact component interactions
4. **Run ui-accessibility-checker** for public-facing applications
5. **Keep handoffs concise** - focus on what next agent needs
6. **Provide stack context** - React version, PrimeReact version, state management
7. **Test responsiveness** early for mobile-first applications
8. **Leverage PrimeReact docs** - reference official examples in handoffs
9. **Use TypeScript** - dramatically improves agent code generation quality
10. **Run verification** between agents if previous agent found critical issues

---

## Agent-Specific Guidance

### For planner agent:
- Identify which PrimeReact components best fit the requirement
- Plan component hierarchy and data flow
- Consider state management approach (Context, Zustand, Redux)
- Define API integration points and error handling strategy

### For ui-generator agent:
- Follow React Hooks best practices (useEffect, custom hooks)
- Use PrimeReact components with proper configuration
- Implement TypeScript interfaces for props and state
- Apply responsive design patterns from the start

### For code-reviewer agent:
- Focus on React-specific issues (hooks dependencies, unnecessary re-renders)
- Check for proper TypeScript typing
- Validate error boundaries and error handling
- Review performance optimizations (memo, useCallback, useMemo)

### For ui-reviewer agent:
- Use Playwright to test PrimeReact component interactions
- Validate responsive behavior across devices
- Test form validation and error states
- Verify loading states and skeletons

### For ui-accessibility-checker agent:
- Validate WCAG 2.1 compliance
- Test keyboard navigation (Tab, Enter, Escape for dialogs)
- Check ARIA attributes on PrimeReact components
- Verify screen reader compatibility
- Test focus management in modals and dialogs
