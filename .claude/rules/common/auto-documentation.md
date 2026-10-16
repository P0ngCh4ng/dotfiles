# Automatic Documentation Generation and Maintenance

Keep architecture and database docs current so project context survives across sessions. Docs should answer: architecture (components, layers, patterns), DB design (schema, relations, indexes), where things live, and key decisions/trade-offs.

## Standard Structure

```
.claude/
├── architecture/  overview.md · components.md · data-flow.md · decisions.md (ADRs)
├── database/      schema.md · erd.md (Mermaid) · migrations.md · queries.md
├── api/           endpoints.md · contracts.md          (if applicable)
└── context/       session-state.json (auto) · current-task.md
```

## When

| Moment | Condition | Action |
|---|---|---|
| Session start | `.claude/architecture/` or `.claude/database/` missing | Ask: "ドキュメントがありません。コードベースを解析して生成しますか？" Yes → generate; partial → ask which; No → remind next session |
| During session | 3+ files / 100+ lines changed, new migration, new routes, new dirs / major refactor | Ask "🔄 構成/DBに変更あり。ドキュメントを更新しますか？" → approve → launch `doc-updater`; decline → re-suggest after 5+ more changes |
| Session end | Major changes and docs stale | Ask whether to update now / defer / skip |
| Explicit | `/update-architecture`, `/update-database`, `/update-docs` (both + codemaps, in parallel) | Launch `doc-updater` |

Propose, don't force. Respect users who want manual control.

## How to Generate

**Architecture**: scan structure → detect stack (package.json, requirements.txt, go.mod…) → identify pattern (MVC, Clean, layered, microservices) → list components (controllers, services, models, middleware) → trace request → response flow → write with Mermaid diagrams (layers, data flow, folder tree with explanations, design patterns, key decisions).

**Database**: detect DB type → extract schema from migrations/models/DB → foreign keys & relations → indexes and their purpose → Mermaid `erDiagram` + per-table column tables (column, type, constraints, description) + common queries with optimization notes.

For complex codebases, run a `general-purpose` agent for deep analysis first, then `doc-updater` to write the docs.

## Quality Bar

- ✅ < 500 lines per file, Mermaid diagrams, structured tables, verified against the code, updated within 30 days
- ❌ > 1000 lines, text-only, out of sync with code, > 90 days stale
- Accurate 100 lines beats inaccurate 1000. Remove outdated sections; link instead of copying.

## Context Budget

Don't load all docs at session start — load the relevant doc when the task needs it. `CLAUDE.md` holds only the doc path plus a 1–2 line summary, e.g.:

```markdown
## Architecture
See `.claude/architecture/overview.md`. Summary: MVC, Express + PostgreSQL, REST API.
```

## Integration

- `/plan`: load architecture docs first; if missing, offer to generate.
- `/tdd`: load schema (data-layer tests) or API contracts (endpoint tests).
- `/document`: update `.claude/architecture/` and `.claude/database/` before user-facing docs.
- Commit docs together with the code changes they describe.
