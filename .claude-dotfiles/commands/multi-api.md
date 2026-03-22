# Plan - Multi-Model Collaborative API Development Planning

Multi-model collaborative planning for RESTful and GraphQL API projects - Context retrieval + Dual-model analysis → Generate comprehensive API implementation plan with OpenAPI/Swagger specification.

$ARGUMENTS

---

## Core Protocols

- **Language Protocol**: Use **English** when interacting with tools/models, communicate with user in their language
- **Mandatory Parallel**: Codex/Gemini calls MUST use `run_in_background: true` (including single model calls, to avoid blocking main thread)
- **Code Sovereignty**: External models have **zero filesystem write access**, all modifications by Claude
- **Stop-Loss Mechanism**: Do not proceed to next phase until current phase output is validated
- **Planning Only**: This command allows reading context and writing to `.claude/plan/*` plan files, but **NEVER modify production code**
- **API Development Awareness**: Backend API logic → Codex authority, API UX/Developer Experience → Gemini authority

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
  API Type: <RESTful|GraphQL|Hybrid>
  Backend: <Node.js/Express|Python/FastAPI|Go/Gin|Ruby/Rails|etc>
  Documentation: OpenAPI 3.0/Swagger, API Blueprint, GraphQL Schema
  Validation: <Joi|Yup|Zod|class-validator|etc>
  Authentication: <JWT|OAuth2|API Keys|etc>
  Rate Limiting: <express-rate-limit|rate-limiter-flexible|etc>
</TASK>
OUTPUT: Step-by-step API implementation plan with contract definitions. DO NOT modify any files.
EOF",
  run_in_background: true,
  timeout: 3600000,
  description: "Brief description"
})
```

**Model Parameter Notes**:
- `{{GEMINI_MODEL_FLAG}}`: When using `--backend gemini`, replace with `--gemini-model gemini-3-pro-preview` (note trailing space); use empty string for codex

**Role Prompts**:

| Phase | Codex (Backend API Logic) | Gemini (API UX/Developer Experience) |
|-------|---------------------------|--------------------------------------|
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
   - API routes: `Glob("routes/**/*.{js,ts,py,go,rb}")`, `Glob("api/**/*.{js,ts,py,go,rb}")`
   - Controllers/Handlers: `Glob("controllers/**/*.{js,ts,py,go,rb}")`, `Glob("handlers/**/*.{js,ts,py,go,rb}")`
   - Models/Schemas: `Glob("models/**/*.{js,ts,py,go,rb}")`, `Glob("schemas/**/*.{js,ts,py,go,rb,graphql}")`
   - Middleware: `Glob("middleware/**/*.{js,ts,py,go,rb}")`
   - API docs: `Glob("**/{openapi,swagger}.{yaml,yml,json}")`, `Glob("docs/api/**/*")`
2. **Grep**: Search for API endpoints, validation schemas, authentication logic
   - Express routes: `Grep("router\\.(get|post|put|delete|patch)", type: "ts")`
   - FastAPI endpoints: `Grep("@app\\.(get|post|put|delete|patch)", type: "py")`
   - GraphQL resolvers: `Grep("(Query|Mutation|Subscription):\\s*{", type: "ts")`
   - OpenAPI specs: `Grep("openapi:|swagger:", glob: "*.{yaml,yml,json}")`
3. **Read**: Read the discovered files to gather complete context
4. **Task (general-purpose agent)**: For deeper exploration, use `Task` with `subagent_type: "general-purpose"` to search across the codebase

#### 1.3 API-Specific Context

Retrieve and analyze:
- **API Structure**:
  - Existing API endpoints and routes
  - Request/response schemas and data models
  - Authentication and authorization mechanisms
  - Validation rules and schemas
  - Error handling patterns
  - Rate limiting configurations
  - API versioning strategy
- **Documentation**:
  - OpenAPI/Swagger specifications
  - GraphQL schema definitions
  - API Blueprint or other documentation
  - Developer guides and examples
- **Infrastructure**:
  - Middleware stack (auth, logging, rate limiting, CORS, etc.)
  - Database models and relationships
  - External service integrations
  - Caching strategies
  - Testing infrastructure

#### 1.4 Completeness Check

- Must obtain **complete definitions and signatures** for relevant endpoints, schemas, middleware
- Verify API contract consistency (routes ↔ handlers ↔ documentation)
- If context insufficient, trigger **recursive retrieval**
- Prioritize output: file path + line number + key symbol name; add minimal code snippets only when necessary to resolve ambiguity

#### 1.5 Requirement Alignment

- If requirements still have ambiguity, **MUST** output guiding questions for user
- Until requirement boundaries are clear (no omissions, no redundancy)
- Clarify: API type (RESTful/GraphQL/both), versioning strategy, authentication method, rate limiting needs

### Phase 2: Multi-Model Collaborative Analysis

`[Mode: Analysis]`

#### 2.1 Distribute Inputs

**Parallel call** Codex and Gemini (`run_in_background: true`):

Distribute **original requirement** (without preset opinions) to both models:

1. **Codex Backend API Logic Analysis**:
   - ROLE_FILE: `~/.claude/.ccg/prompts/codex/analyzer.md`
   - Focus: API architecture, endpoint design, data validation, authentication/authorization, rate limiting, error handling, database schema, caching strategy, performance optimization, security best practices
   - OUTPUT: Multi-perspective solutions + pros/cons analysis + API endpoint design + validation schemas

2. **Gemini API UX/Developer Experience Analysis**:
   - ROLE_FILE: `~/.claude/.ccg/prompts/gemini/analyzer.md`
   - Focus: API design patterns, developer ergonomics, documentation quality, error messages clarity, request/response structure, SDK design considerations, versioning strategy, backward compatibility, API consistency
   - OUTPUT: Multi-perspective solutions + pros/cons analysis + developer experience recommendations

Wait for both models' complete results with `TaskOutput`. **Save SESSION_ID** (`CODEX_SESSION` and `GEMINI_SESSION`).

#### 2.2 Cross-Validation

Integrate perspectives and iterate for optimization:

1. **Identify consensus** (strong signal)
2. **Identify divergence** (needs weighing)
3. **Complementary strengths**: Backend logic/security follows Codex, API design/DX follows Gemini
4. **API Contract Validation**: Ensure OpenAPI specs align with implementation design
5. **Logical reasoning**: Eliminate logical gaps in solutions
6. **Security review**: Validate authentication, authorization, rate limiting, input sanitization

#### 2.3 (Optional but Recommended) Dual-Model Plan Draft

To reduce risk of omissions in Claude's synthesized plan, can parallel have both models output "plan drafts" (still **NOT allowed** to modify files):

1. **Codex Plan Draft (Backend API Logic Authority)**:
   - ROLE_FILE: `~/.claude/.ccg/prompts/codex/architect.md`
   - OUTPUT: Step-by-step plan + pseudo-code
     - Database schema design (tables, indexes, relationships)
     - Data models and ORM setup
     - Validation schemas (request validation)
     - Authentication middleware (JWT, OAuth2, API keys)
     - Authorization logic (permissions, roles, scopes)
     - Rate limiting implementation
     - API endpoint handlers (CRUD operations, business logic)
     - Error handling and logging
     - Caching layer (Redis, in-memory, etc.)
     - Background jobs (if needed)
     - Testing strategy (unit tests, integration tests)
     - Security considerations (SQL injection, XSS, CSRF, etc.)

2. **Gemini Plan Draft (API UX/Developer Experience Authority)**:
   - ROLE_FILE: `~/.claude/.ccg/prompts/gemini/architect.md`
   - OUTPUT: Step-by-step plan + pseudo-code
     - API endpoint structure and naming conventions
     - Request/response format standardization
     - Versioning strategy (URL-based, header-based, content negotiation)
     - OpenAPI/Swagger specification structure
     - Error response format and status codes
     - Pagination, filtering, sorting patterns
     - Webhook design (if applicable)
     - SDK considerations and example code
     - API documentation structure
     - Developer onboarding flow
     - Breaking change management
     - Deprecation strategy

Wait for both models' complete results with `TaskOutput`, record key differences in their suggestions.

#### 2.4 Generate Implementation Plan (Claude Final Version)

Synthesize both analyses, generate **Step-by-step API Implementation Plan**:

```markdown
## API Implementation Plan: <Task Name>

### API Type
- [ ] RESTful API (→ Codex + Gemini)
- [ ] GraphQL API (→ Codex + Gemini)
- [ ] Hybrid (REST + GraphQL)

### Technical Solution
<Optimal solution synthesized from Codex + Gemini analysis>

### API Contract Definition

#### RESTful Endpoints
| Endpoint | Method | Auth | Request | Response | Status Codes |
|----------|--------|------|---------|----------|--------------|
| /api/v1/resources | GET | JWT | Query params | { data: Resource[] } | 200, 401, 403, 500 |
| /api/v1/resources/:id | GET | JWT | Path param | { data: Resource } | 200, 401, 403, 404, 500 |
| /api/v1/resources | POST | JWT | { field: type } | { data: Resource } | 201, 400, 401, 403, 422, 500 |
| /api/v1/resources/:id | PUT | JWT | { field: type } | { data: Resource } | 200, 400, 401, 403, 404, 422, 500 |
| /api/v1/resources/:id | DELETE | JWT | Path param | { message: string } | 204, 401, 403, 404, 500 |

#### GraphQL Schema (if applicable)
```graphql
type Resource {
  id: ID!
  field: String!
  createdAt: DateTime!
  updatedAt: DateTime!
}

type Query {
  resources(limit: Int, offset: Int): [Resource!]!
  resource(id: ID!): Resource
}

type Mutation {
  createResource(input: CreateResourceInput!): Resource!
  updateResource(id: ID!, input: UpdateResourceInput!): Resource!
  deleteResource(id: ID!): Boolean!
}
```

### Request/Response Schemas

#### Standard Response Format
```json
{
  "success": true,
  "data": { ... },
  "meta": {
    "timestamp": "2026-03-11T12:00:00Z",
    "version": "v1"
  }
}
```

#### Standard Error Format
```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid request data",
    "details": [
      {
        "field": "email",
        "message": "Email is required"
      }
    ]
  },
  "meta": {
    "timestamp": "2026-03-11T12:00:00Z",
    "version": "v1"
  }
}
```

### Implementation Steps

#### 1. OpenAPI/Swagger Specification
- **File**: `docs/openapi.yaml` or `swagger.json`
- **Actions**:
  - Define API metadata (title, version, description, servers)
  - Define authentication schemes (JWT, OAuth2, API Key)
  - Define all endpoint paths and operations
  - Define request/response schemas using JSON Schema
  - Define error responses and status codes
  - Add examples for all endpoints
  - Configure Swagger UI integration

#### 2. Database Schema
- **Migration Files**: `migrations/YYYY_MM_DD_create_tables.{sql,js,py,go}`
- **Actions**:
  - Design database tables with proper types and constraints
  - Add indexes for query optimization
  - Set up foreign keys and relationships
  - Create seed data for development/testing

#### 3. Data Models
- **Files**: `models/Resource.{js,ts,py,go,rb}`
- **Actions**:
  - Define model classes/structs with field types
  - Implement model relationships (ORM)
  - Add virtual fields/computed properties
  - Implement serialization methods
  - Add model-level validation

#### 4. Validation Schemas
- **Files**: `schemas/resourceSchema.{js,ts,py,go}` or `validators/resourceValidator.{js,ts,py,go}`
- **Actions**:
  - Define request validation schemas (Joi, Yup, Zod, Pydantic, etc.)
  - Implement validation for create/update operations
  - Add custom validation rules
  - Define sanitization rules
  - Set up validation error messages

#### 5. Authentication Middleware
- **Files**: `middleware/auth.{js,ts,py,go,rb}`
- **Actions**:
  - Implement JWT token verification
  - Set up OAuth2 flow (if applicable)
  - Implement API key validation (if applicable)
  - Add token refresh mechanism
  - Handle authentication errors
  - Add user context to requests

#### 6. Authorization Middleware
- **Files**: `middleware/permissions.{js,ts,py,go,rb}`
- **Actions**:
  - Implement role-based access control (RBAC)
  - Set up permission checking
  - Implement scope validation (for OAuth2)
  - Add resource-level authorization
  - Handle authorization errors

#### 7. Rate Limiting
- **Files**: `middleware/rateLimit.{js,ts,py,go,rb}`
- **Actions**:
  - Configure rate limiting strategy (sliding window, token bucket, etc.)
  - Set up rate limit storage (Redis, in-memory, etc.)
  - Define rate limits per endpoint/user/IP
  - Add rate limit headers (X-RateLimit-*)
  - Handle rate limit exceeded errors

#### 8. API Versioning
- **Strategy**: URL-based (`/api/v1/`), Header-based (`Accept: application/vnd.api+json; version=1`), or Content Negotiation
- **Actions**:
  - Set up version routing
  - Implement version detection middleware
  - Plan deprecation strategy for old versions
  - Document version differences
  - Set up version-specific controllers/handlers

#### 9. API Endpoints/Routes
- **Files**: `routes/api.{js,ts,py,go,rb}` or `controllers/resourceController.{js,ts,py,go,rb}`
- **Actions**:
  - Register all API routes with middleware
  - Implement GET endpoints (list, single, search, filtering)
  - Implement POST endpoints (create resources)
  - Implement PUT/PATCH endpoints (update resources)
  - Implement DELETE endpoints (soft delete or hard delete)
  - Add pagination support (limit, offset, cursor-based)
  - Add filtering and sorting support
  - Add search functionality (full-text, fuzzy, etc.)

#### 10. Error Handling
- **Files**: `middleware/errorHandler.{js,ts,py,go,rb}` or `utils/errors.{js,ts,py,go,rb}`
- **Actions**:
  - Define error classes/types (ValidationError, NotFoundError, etc.)
  - Implement global error handler middleware
  - Map errors to HTTP status codes
  - Standardize error response format
  - Add error logging (winston, bunyan, logrus, etc.)
  - Implement error tracking (Sentry, Rollbar, etc.)
  - Handle uncaught exceptions gracefully

#### 11. Logging and Monitoring
- **Files**: `middleware/logger.{js,ts,py,go,rb}`
- **Actions**:
  - Set up request/response logging
  - Log authentication/authorization events
  - Log database queries (in development)
  - Add performance metrics (response time, throughput)
  - Integrate with monitoring tools (Prometheus, Grafana, Datadog, etc.)
  - Set up alerting for errors and anomalies

#### 12. Caching Layer (if needed)
- **Files**: `services/cache.{js,ts,py,go,rb}`
- **Actions**:
  - Set up Redis or in-memory cache
  - Implement cache middleware
  - Define cache keys and TTL
  - Add cache invalidation logic
  - Cache frequently accessed resources
  - Add cache headers (ETag, Cache-Control)

#### 13. API Documentation
- **Files**: `docs/README.md`, `docs/authentication.md`, `docs/examples.md`
- **Actions**:
  - Write API overview and getting started guide
  - Document authentication and authorization
  - Provide code examples for each endpoint
  - Document error codes and responses
  - Add rate limiting documentation
  - Create API changelog
  - Set up Swagger UI or Redoc for interactive docs
  - Generate SDK documentation (if applicable)

#### 14. Testing
- **Files**: `tests/api/**/*.test.{js,ts,py,go,rb}` or `__tests__/api/**/*.spec.{js,ts,py,go,rb}`
- **Actions**:
  - Unit tests for validation schemas
  - Unit tests for middleware (auth, rate limit, etc.)
  - Integration tests for API endpoints
  - Test authentication flows
  - Test authorization rules
  - Test error handling
  - Test rate limiting
  - Test pagination and filtering
  - Load testing (k6, JMeter, Artillery, etc.)
  - Security testing (OWASP top 10)

#### 15. API Security
- **Actions**:
  - Implement input sanitization (prevent SQL injection, XSS, etc.)
  - Add CORS configuration
  - Set up HTTPS/TLS
  - Implement CSRF protection (if applicable)
  - Add security headers (Helmet.js, etc.)
  - Implement request size limits
  - Add IP whitelisting/blacklisting (if needed)
  - Set up API key rotation mechanism
  - Implement audit logging for sensitive operations

### Key Files
| File | Operation | Description |
|------|-----------|-------------|
| docs/openapi.yaml | Create | OpenAPI 3.0 specification |
| routes/api.{js,ts,py,go} | Modify | API route definitions |
| controllers/resourceController.{js,ts,py,go} | Create | API endpoint handlers |
| middleware/auth.{js,ts,py,go} | Create | Authentication middleware |
| middleware/rateLimit.{js,ts,py,go} | Create | Rate limiting middleware |
| schemas/resourceSchema.{js,ts,py,go} | Create | Request validation schemas |
| models/Resource.{js,ts,py,go} | Create | Data model definition |
| tests/api/resource.test.{js,ts,py,go} | Create | API endpoint tests |

### Technology Stack
- **API Type**: RESTful / GraphQL / Hybrid
- **Backend Framework**: Express / FastAPI / Gin / Rails / etc.
- **Database**: PostgreSQL / MySQL / MongoDB / etc.
- **Validation**: Joi / Yup / Zod / Pydantic / class-validator / etc.
- **Authentication**: JWT / OAuth2 / API Keys / Passport.js / etc.
- **Rate Limiting**: express-rate-limit / rate-limiter-flexible / etc.
- **Documentation**: Swagger UI / Redoc / GraphQL Playground / etc.
- **Testing**: Jest / pytest / testing package / RSpec / etc.
- **Monitoring**: Prometheus / Grafana / Datadog / New Relic / etc.

### API Design Best Practices
- **RESTful Conventions**:
  - Use nouns for resource names (not verbs)
  - Use plural nouns (`/users`, not `/user`)
  - Use HTTP methods correctly (GET, POST, PUT, PATCH, DELETE)
  - Use proper status codes (2xx success, 4xx client error, 5xx server error)
  - Support filtering, sorting, pagination
  - Use HATEOAS links for discoverability (optional)
- **GraphQL Conventions**:
  - Use clear, descriptive type names
  - Implement proper error handling (union types, error extensions)
  - Use pagination for lists (connection pattern, relay-style)
  - Implement field-level authorization
  - Add deprecation notices for deprecated fields
- **Developer Experience**:
  - Consistent naming conventions
  - Clear error messages with actionable guidance
  - Comprehensive documentation with examples
  - API playground or sandbox environment
  - Versioning strategy for breaking changes
  - Changelog for API updates
- **Security**:
  - Always use HTTPS
  - Validate and sanitize all inputs
  - Implement rate limiting
  - Use authentication for protected resources
  - Implement proper authorization checks
  - Don't expose sensitive data in responses
  - Log security events

### Versioning Strategy
- **Approach**: URL-based (`/api/v1/`, `/api/v2/`) / Header-based / Content negotiation
- **Breaking Changes**: How to handle (new version, deprecation warnings, sunset dates)
- **Backward Compatibility**: Support multiple versions simultaneously
- **Deprecation Process**: Announce → deprecation warnings → sunset → removal

### Rate Limiting Strategy
- **Limits**: Per endpoint, per user, per IP
- **Algorithm**: Sliding window / Token bucket / Leaky bucket
- **Response**: HTTP 429 Too Many Requests with Retry-After header
- **Headers**: X-RateLimit-Limit, X-RateLimit-Remaining, X-RateLimit-Reset

### Error Handling Strategy
| Error Type | HTTP Status | Error Code | Example |
|------------|-------------|------------|---------|
| Validation Error | 422 | VALIDATION_ERROR | Invalid email format |
| Not Found | 404 | RESOURCE_NOT_FOUND | Resource with ID not found |
| Unauthorized | 401 | UNAUTHORIZED | Missing or invalid token |
| Forbidden | 403 | FORBIDDEN | Insufficient permissions |
| Rate Limit | 429 | RATE_LIMIT_EXCEEDED | Too many requests |
| Server Error | 500 | INTERNAL_ERROR | Unexpected server error |

### Risks and Mitigation
| Risk | Mitigation |
|------|------------|
| API contract breaking changes | Implement versioning, maintain backward compatibility |
| Security vulnerabilities | Input validation, authentication, rate limiting, security audits |
| Performance bottlenecks | Caching, database indexing, load testing, CDN for static assets |
| Scalability issues | Horizontal scaling, load balancing, database replication |
| Documentation drift | Auto-generate docs from code, keep OpenAPI spec in sync |
| Poor developer experience | Clear error messages, comprehensive docs, API playground |

### SESSION_ID (for /ccg:execute use)
- CODEX_SESSION: <session_id>
- GEMINI_SESSION: <session_id>
```

### Phase 2 End: Plan Delivery (Not Execution)

**`/multi-api` responsibilities end here, MUST execute the following actions**:

1. Present complete API implementation plan to user (including pseudo-code and OpenAPI spec outline)
2. Save plan to `.claude/plan/<api-feature-name>.md` (extract feature name from requirement, e.g., `user-api`, `payment-api`, `product-catalog-api`)
3. Output prompt in **bold text** (MUST use actual saved file path):

   ---
   **API Plan generated and saved to `.claude/plan/actual-api-feature-name.md`**

   **Please review the API plan above. You can:**
   - **Modify plan**: Tell me what needs adjustment, I'll update the plan
   - **Execute plan**: Copy the following command to a new session

   ```
   /ccg:execute .claude/plan/actual-api-feature-name.md
   ```
   ---

   **NOTE**: The `actual-api-feature-name.md` above MUST be replaced with the actual saved filename!

4. **Immediately terminate current response** (Stop here. No more tool calls.)

**ABSOLUTELY FORBIDDEN**:
- Ask user "Y/N" then auto-execute (execution is `/ccg:execute`'s responsibility)
- Any write operations to production code
- Automatically call `/ccg:execute` or any implementation actions
- Continue triggering model calls when user hasn't explicitly requested modifications

---

## Plan Saving

After planning completes, save plan to:

- **First planning**: `.claude/plan/<api-feature-name>.md`
- **Iteration versions**: `.claude/plan/<api-feature-name>-v2.md`, `.claude/plan/<api-feature-name>-v3.md`...

Plan file write should complete before presenting plan to user.

---

## Plan Modification Flow

If user requests plan modifications:

1. Adjust plan content based on user feedback
2. Update `.claude/plan/<api-feature-name>.md` file
3. Re-present modified plan
4. Prompt user to review or execute again

---

## Next Steps

After user approves, **manually** execute:

```bash
/ccg:execute .claude/plan/<api-feature-name>.md
```

---

## API Development Best Practices

### RESTful API Design
- Use resource-based URLs (nouns, not verbs)
- Use HTTP methods semantically (GET, POST, PUT, PATCH, DELETE)
- Use proper status codes (200, 201, 204, 400, 401, 403, 404, 422, 429, 500)
- Implement consistent response formats
- Support filtering, sorting, pagination
- Use plural nouns for collections
- Version your API from the start
- Implement HATEOAS for API discoverability (optional)

### GraphQL API Design
- Design schema-first before implementation
- Use clear, descriptive type and field names
- Implement proper error handling with error extensions
- Use pagination for lists (connection pattern)
- Implement field-level authorization
- Add deprecation notices instead of removing fields
- Use DataLoader for N+1 query prevention
- Implement query complexity analysis and limits

### Validation
- Validate all inputs at API boundary
- Use schema validation libraries (Joi, Yup, Zod, Pydantic, etc.)
- Provide clear, actionable error messages
- Validate data types, formats, ranges, patterns
- Implement custom validation rules for business logic
- Sanitize inputs to prevent injection attacks
- Return field-level validation errors

### Authentication
- Use industry-standard methods (JWT, OAuth2, API Keys)
- Implement token expiration and refresh
- Use HTTPS for all authenticated endpoints
- Store tokens securely (httpOnly cookies, secure storage)
- Implement token revocation mechanism
- Use strong password hashing (bcrypt, Argon2)
- Implement account lockout after failed attempts

### Authorization
- Implement role-based access control (RBAC)
- Use permission-based authorization
- Implement resource-level authorization
- Check permissions on every request
- Use scopes for OAuth2
- Fail closed (deny by default)
- Audit authorization decisions

### Rate Limiting
- Implement rate limiting per user, per IP, per endpoint
- Use appropriate algorithms (sliding window, token bucket)
- Return proper headers (X-RateLimit-*)
- Return 429 status with Retry-After header
- Allow higher limits for authenticated users
- Implement burst protection
- Monitor and adjust limits based on usage

### Versioning
- Choose versioning strategy early (URL, header, content negotiation)
- Support multiple versions simultaneously
- Document version differences clearly
- Plan deprecation strategy (announce → warn → sunset → remove)
- Use semantic versioning (v1, v2, v3)
- Maintain backward compatibility when possible
- Provide migration guides for breaking changes

### Error Handling
- Use consistent error response format
- Include error codes for programmatic handling
- Provide clear, actionable error messages
- Don't expose internal implementation details
- Log errors for debugging (without exposing to clients)
- Use appropriate HTTP status codes
- Include request ID for tracing
- Handle edge cases gracefully

### Documentation
- Write clear, comprehensive API documentation
- Generate documentation from OpenAPI/GraphQL schema
- Provide code examples in multiple languages
- Document authentication and authorization
- Document rate limits and quotas
- Include error codes and responses
- Provide getting started guide
- Set up interactive API playground (Swagger UI, GraphQL Playground)
- Keep documentation in sync with implementation
- Maintain changelog for API updates

### Testing
- Write unit tests for validation, middleware, utilities
- Write integration tests for API endpoints
- Test authentication and authorization flows
- Test error handling and edge cases
- Test rate limiting behavior
- Implement load testing and performance benchmarks
- Test security vulnerabilities (OWASP top 10)
- Use contract testing for API consumers
- Automate testing in CI/CD pipeline

### Security
- Use HTTPS/TLS for all endpoints
- Validate and sanitize all inputs
- Implement authentication and authorization
- Use rate limiting and throttling
- Implement CORS properly
- Add security headers (CSP, X-Frame-Options, etc.)
- Prevent SQL injection, XSS, CSRF attacks
- Don't expose sensitive data in responses
- Implement audit logging for sensitive operations
- Keep dependencies updated
- Conduct security audits and penetration testing

### Performance
- Implement caching (Redis, CDN, HTTP caching)
- Use database indexes for queries
- Implement pagination for large datasets
- Use connection pooling for databases
- Optimize database queries (N+1 prevention)
- Compress responses (gzip, brotli)
- Use CDN for static assets
- Implement request/response streaming for large data
- Monitor performance metrics (response time, throughput)
- Load test and optimize bottlenecks

### Developer Experience
- Design intuitive, consistent API
- Provide clear, actionable error messages
- Write comprehensive documentation
- Provide code examples and SDKs
- Offer API sandbox/playground environment
- Provide webhooks for event notifications
- Use standard conventions and patterns
- Respond to developer feedback
- Maintain API changelog
- Provide migration guides for breaking changes

---

## Key Rules

1. **Plan only, no implementation** – This command does not execute any code changes
2. **No Y/N prompts** – Only present plan, let user decide next steps
3. **Trust Rules** – Backend API logic follows Codex, API UX/Developer Experience follows Gemini
4. External models have **zero filesystem write access**
5. **SESSION_ID Handoff** – Plan must include `CODEX_SESSION` / `GEMINI_SESSION` at end (for `/ccg:execute resume <SESSION_ID>` use)
6. **OpenAPI First** – Always define OpenAPI/GraphQL schema before detailed planning
7. **Security Priority** – Authentication, authorization, validation, rate limiting are non-negotiable
8. **Documentation Mandatory** – API without documentation is incomplete
