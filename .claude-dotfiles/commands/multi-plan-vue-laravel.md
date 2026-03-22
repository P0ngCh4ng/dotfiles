# Plan - Vue+Laravel Multi-Model Collaborative Planning

Multi-model collaborative planning for Vue.js frontend + Laravel backend projects - Context retrieval + Dual-model analysis → Generate step-by-step implementation plan.

$ARGUMENTS

---

## Core Protocols

- **Language Protocol**: Use **English** when interacting with tools/models, communicate with user in their language
- **Mandatory Parallel**: Codex/Gemini calls MUST use `run_in_background: true` (including single model calls, to avoid blocking main thread)
- **Code Sovereignty**: External models have **zero filesystem write access**, all modifications by Claude
- **Stop-Loss Mechanism**: Do not proceed to next phase until current phase output is validated
- **Planning Only**: This command allows reading context and writing to `.claude/plan/*` plan files, but **NEVER modify production code**
- **Vue+Laravel Awareness**: Frontend (Vue.js, Composition API, Pinia) → Gemini authority, Backend (Laravel, Eloquent, API Resources) → Codex authority

---

## Multi-Model Call Specification

**Call Syntax** (parallel: use `run_in_background: true`):

```
Bash({
  command: "~/.claude/bin/codeagent-wrapper {{LITE_MODE_FLAG}}--backend <codex|gemini> {{GEMINI_MODEL_FLAG}}- \"$PWD\" <<'EOF'
ROLE_FILE: <role prompt path>
<TASK>
Requirement: <enhanced requirement>
Context: <retrieved project context>
Stack Context:
  Frontend: Vue 3 (Composition API, <script setup>, TypeScript), Pinia (state management), Vue Router, Vite
  Backend: Laravel 11 (PHP 8.3+, Eloquent ORM, API Resources, Form Requests, Service Layer)
  API: RESTful JSON API, Laravel Sanctum for authentication
</TASK>
OUTPUT: Step-by-step implementation plan with pseudo-code. DO NOT modify any files.
EOF",
  run_in_background: true,
  timeout: 3600000,
  description: "Brief description"
})
```

**Model Parameter Notes**:
- `{{GEMINI_MODEL_FLAG}}`: When using `--backend gemini`, replace with `--gemini-model gemini-3-pro-preview` (note trailing space); use empty string for codex

**Role Prompts**:

| Phase | Codex (Laravel Backend) | Gemini (Vue Frontend) |
|-------|-------------------------|------------------------|
| Analysis | `~/.claude/.ccg/prompts/codex/analyzer.md` | `~/.claude/.ccg/prompts/gemini/analyzer.md` |
| Planning | `~/.claude/.ccg/prompts/codex/architect.md` | `~/.claude/.ccg/prompts/gemini/architect.md` |

**Session Reuse**: Each call returns `SESSION_ID: xxx` (typically output by wrapper), **MUST save** for subsequent `/ccg:execute` use.

**Wait for Background Tasks** (max timeout 600000ms = 10 minutes):

```
TaskOutput({ task_id: "<task_id>", block: true, timeout: 600000 })
```

**IMPORTANT**:
- Must specify `timeout: 600000`, otherwise default 30 seconds will cause premature timeout
- If still incomplete after 10 minutes, continue polling with `TaskOutput`, **NEVER kill the process**
- If waiting is skipped due to timeout, **MUST call `AskUserQuestion` to ask user whether to continue waiting or kill task**

---

## Execution Workflow

**Planning Task**: $ARGUMENTS

### Phase 1: Full Context Retrieval

`[Mode: Research]`

#### 1.1 Prompt Enhancement (MUST execute first)

**If ace-tool MCP is available**, call `mcp__ace-tool__enhance_prompt` tool:

```
mcp__ace-tool__enhance_prompt({
  prompt: "$ARGUMENTS",
  conversation_history: "<last 5-10 conversation turns>",
  project_root_path: "$PWD"
})
```

Wait for enhanced prompt, **replace original $ARGUMENTS with enhanced result** for all subsequent phases.

**If ace-tool MCP is NOT available**: Skip this step and use the original `$ARGUMENTS` as-is for all subsequent phases.

#### 1.2 Context Retrieval

**If ace-tool MCP is available**, call `mcp__ace-tool__search_context` tool:

```
mcp__ace-tool__search_context({
  query: "<semantic query based on enhanced requirement>",
  project_root_path: "$PWD"
})
```

- Build semantic query using natural language (Where/What/How)
- **NEVER answer based on assumptions**

**If ace-tool MCP is NOT available**, use Claude Code built-in tools as fallback:
1. **Glob**: Find relevant files by pattern
   - Vue components: `Glob("resources/js/**/*.vue")`, `Glob("resources/js/components/**/*.vue")`
   - Vue composables: `Glob("resources/js/composables/**/*.ts")`
   - Laravel controllers: `Glob("app/Http/Controllers/**/*.php")`
   - Models: `Glob("app/Models/**/*.php")`
   - API routes: `Glob("routes/api.php")`
2. **Grep**: Search for key symbols, components, API endpoints
   - Vue components: `Grep("export default defineComponent|<script setup", type: "ts")`
   - Laravel routes: `Grep("Route::(get|post|put|delete)", path: "routes/api.php")`
   - Eloquent models: `Grep("class .* extends Model")`
3. **Read**: Read the discovered files to gather complete context
4. **Task (general-purpose agent)**: For deeper exploration, use `Task` with `subagent_type: "general-purpose"` to search across the codebase

#### 1.3 Vue+Laravel Specific Context

Retrieve and analyze:
- **Frontend Structure**:
  - Vue component hierarchy (`resources/js/components/`, `resources/js/views/`)
  - Pinia stores (`resources/js/stores/`)
  - API service layer (`resources/js/services/api.ts` or similar)
  - Router configuration (`resources/js/router/`)
- **Backend Structure**:
  - API endpoints (`routes/api.php`)
  - Controllers (`app/Http/Controllers/`)
  - Models and relationships (`app/Models/`)
  - Form Requests (`app/Http/Requests/`)
  - API Resources (`app/Http/Resources/`)
  - Services (`app/Services/`)

#### 1.4 Completeness Check

- Must obtain **complete definitions and signatures** for relevant classes, functions, variables
- Verify API contract consistency (Laravel routes ↔ Vue API calls)
- If context insufficient, trigger **recursive retrieval**
- Prioritize output: entry file + line number + key symbol name; add minimal code snippets only when necessary to resolve ambiguity

#### 1.5 Requirement Alignment

- If requirements still have ambiguity, **MUST** output guiding questions for user
- Until requirement boundaries are clear (no omissions, no redundancy)

### Phase 2: Multi-Model Collaborative Analysis

`[Mode: Analysis]`

#### 2.1 Distribute Inputs

**Parallel call** Codex and Gemini (`run_in_background: true`):

Distribute **original requirement** (without preset opinions) to both models:

1. **Codex Backend Analysis (Laravel)**:
   - ROLE_FILE: `~/.claude/.ccg/prompts/codex/analyzer.md`
   - Focus: Laravel API design, Eloquent relationships, validation strategy, service layer architecture, database schema, authentication/authorization, performance considerations
   - OUTPUT: Multi-perspective solutions + pros/cons analysis + API endpoint design

2. **Gemini Frontend Analysis (Vue)**:
   - ROLE_FILE: `~/.claude/.ccg/prompts/gemini/analyzer.md`
   - Focus: Vue component design, Composition API patterns, Pinia state management, API integration, form handling, UI/UX flow, TypeScript types
   - OUTPUT: Multi-perspective solutions + pros/cons analysis + component hierarchy

Wait for both models' complete results with `TaskOutput`. **Save SESSION_ID** (`CODEX_SESSION` and `GEMINI_SESSION`).

#### 2.2 Cross-Validation

Integrate perspectives and iterate for optimization:

1. **Identify consensus** (strong signal)
2. **Identify divergence** (needs weighing)
3. **Complementary strengths**: Backend logic follows Codex, Frontend design follows Gemini
4. **API Contract Validation**: Ensure Laravel API endpoints match Vue service layer expectations
5. **Logical reasoning**: Eliminate logical gaps in solutions

#### 2.3 (Optional but Recommended) Dual-Model Plan Draft

To reduce risk of omissions in Claude's synthesized plan, can parallel have both models output "plan drafts" (still **NOT allowed** to modify files):

1. **Codex Plan Draft (Laravel Backend Authority)**:
   - ROLE_FILE: `~/.claude/.ccg/prompts/codex/architect.md`
   - OUTPUT: Step-by-step plan + pseudo-code
     - Database migrations and seeders
     - Eloquent model setup (relationships, accessors, mutators)
     - Form Request validation rules
     - API Resource transformations
     - Controller logic and service layer
     - API routes definition
     - Test strategy (Feature tests, Unit tests)
     - Error handling and edge cases

2. **Gemini Plan Draft (Vue Frontend Authority)**:
   - ROLE_FILE: `~/.claude/.ccg/prompts/gemini/architect.md`
   - OUTPUT: Step-by-step plan + pseudo-code
     - Component hierarchy and file structure
     - TypeScript interfaces for API responses
     - Pinia store design (state, getters, actions)
     - Composables for reusable logic
     - API service functions
     - Form handling and validation
     - Router configuration
     - UI flow and user experience
     - Accessibility and responsiveness

Wait for both models' complete results with `TaskOutput`, record key differences in their suggestions.

#### 2.4 Generate Implementation Plan (Claude Final Version)

Synthesize both analyses, generate **Step-by-step Implementation Plan**:

```markdown
## Implementation Plan: <Task Name>

### Task Type
- [ ] Frontend (Vue → Gemini)
- [ ] Backend (Laravel → Codex)
- [ ] Fullstack (→ Parallel)

### Technical Solution
<Optimal solution synthesized from Codex + Gemini analysis>

### API Contract
| Endpoint | Method | Request | Response |
|----------|--------|---------|----------|
| /api/resource | POST | { field: type } | { data: Resource } |

### Implementation Steps

#### Backend (Laravel)
1. **Database** - Create migration `YYYY_MM_DD_create_table.php`
2. **Model** - Setup `app/Models/ModelName.php` with relationships
3. **Request** - Create `app/Http/Requests/StoreModelRequest.php` validation
4. **Resource** - Create `app/Http/Resources/ModelResource.php` transformation
5. **Service** - Implement `app/Services/ModelService.php` business logic
6. **Controller** - Create `app/Http/Controllers/ModelController.php` endpoints
7. **Routes** - Register in `routes/api.php`
8. **Tests** - Feature tests for API endpoints

#### Frontend (Vue)
1. **Types** - Define TypeScript interfaces in `resources/js/types/`
2. **API Service** - Create API functions in `resources/js/services/modelService.ts`
3. **Store** - Setup Pinia store `resources/js/stores/modelStore.ts`
4. **Composables** - Create reusable logic in `resources/js/composables/useModel.ts`
5. **Components** - Build Vue components in `resources/js/components/Model/`
6. **Views** - Create page views in `resources/js/views/Model/`
7. **Router** - Configure routes in `resources/js/router/index.ts`
8. **Integration** - Connect components to store and API

### Key Files
| File | Operation | Description |
|------|-----------|-------------|
| routes/api.php:L20-L25 | Add | API routes for resource |
| app/Models/Model.php | Create | Eloquent model |
| resources/js/components/Model/Form.vue | Create | Vue form component |
| resources/js/stores/modelStore.ts | Create | Pinia store |

### Technology Stack Integration
- **Frontend**: Vue 3 Composition API, Pinia, Vue Router, TypeScript, Vite
- **Backend**: Laravel 11, Eloquent ORM, API Resources, Form Requests
- **API**: RESTful JSON, Laravel Sanctum authentication
- **Testing**: Laravel Feature Tests, Vue Test Utils (if applicable)

### Risks and Mitigation
| Risk | Mitigation |
|------|------------|
| API contract mismatch | Define TypeScript interfaces from API Resource structure |
| State management complexity | Use Pinia with typed stores and composables |
| Validation inconsistency | Mirror Laravel validation rules in frontend |

### SESSION_ID (for /ccg:execute use)
- CODEX_SESSION: <session_id>
- GEMINI_SESSION: <session_id>
```

### Phase 2 End: Plan Delivery (Not Execution)

**`/multi-plan-vue-laravel` responsibilities end here, MUST execute the following actions**:

1. Present complete implementation plan to user (including pseudo-code)
2. Save plan to `.claude/plan/<feature-name>.md` (extract feature name from requirement, e.g., `user-profile`, `product-catalog`)
3. Output prompt in **bold text** (MUST use actual saved file path):

   ---
   **Plan generated and saved to `.claude/plan/actual-feature-name.md`**

   **Please review the plan above. You can:**
   - **Modify plan**: Tell me what needs adjustment, I'll update the plan
   - **Execute plan**: Copy the following command to a new session

   ```
   /ccg:execute .claude/plan/actual-feature-name.md
   ```
   ---

   **NOTE**: The `actual-feature-name.md` above MUST be replaced with the actual saved filename!

4. **Immediately terminate current response** (Stop here. No more tool calls.)

**ABSOLUTELY FORBIDDEN**:
- Ask user "Y/N" then auto-execute (execution is `/ccg:execute`'s responsibility)
- Any write operations to production code
- Automatically call `/ccg:execute` or any implementation actions
- Continue triggering model calls when user hasn't explicitly requested modifications

---

## Plan Saving

After planning completes, save plan to:

- **First planning**: `.claude/plan/<feature-name>.md`
- **Iteration versions**: `.claude/plan/<feature-name>-v2.md`, `.claude/plan/<feature-name>-v3.md`...

Plan file write should complete before presenting plan to user.

---

## Plan Modification Flow

If user requests plan modifications:

1. Adjust plan content based on user feedback
2. Update `.claude/plan/<feature-name>.md` file
3. Re-present modified plan
4. Prompt user to review or execute again

---

## Next Steps

After user approves, **manually** execute:

```bash
/ccg:execute .claude/plan/<feature-name>.md
```

---

## Vue+Laravel Best Practices

### Frontend (Vue)
- Use Composition API with `<script setup>` syntax
- Define TypeScript interfaces for all API responses
- Use Pinia for global state, composables for local logic
- Implement proper error handling in API calls
- Use `ref` and `computed` appropriately
- Follow Vue 3 reactivity patterns

### Backend (Laravel)
- Use Form Requests for validation
- Use API Resources for response transformation
- Implement service layer for complex business logic
- Use Eloquent relationships properly
- Follow RESTful API conventions
- Implement proper error handling and API responses
- Use Laravel Sanctum for API authentication

### Integration
- Define clear API contracts before implementation
- Mirror backend validation in frontend when appropriate
- Use TypeScript types derived from API Resource structure
- Implement consistent error handling across stack
- Use proper HTTP status codes

---

## Key Rules

1. **Plan only, no implementation** – This command does not execute any code changes
2. **No Y/N prompts** – Only present plan, let user decide next steps
3. **Trust Rules** – Backend (Laravel) follows Codex, Frontend (Vue) follows Gemini
4. External models have **zero filesystem write access**
5. **SESSION_ID Handoff** – Plan must include `CODEX_SESSION` / `GEMINI_SESSION` at end (for `/ccg:execute resume <SESSION_ID>` use)
6. **API Contract First** – Always define API endpoints and data structures before detailed planning
