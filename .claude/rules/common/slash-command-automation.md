# Slash Command Automation Rules

Slash commands below launch their agents automatically, without asking. "∥" = launch in parallel (same message); "→" = sequential (wait for the previous result).

## Command → Agent Map

| Command | Agents | Timing |
|---|---|---|
| `/plan` | `planner` ∥ `code-reviewer` (pre-implementation security/quality analysis) | Immediately |
| `/tdd` | `planner` (test-case planning) → implement → `code-reviewer` (tests + impl + coverage) | Phase 1 / Phase 5 |
| `/quality-gate` | `code-reviewer` ∥ `doc-updater` | Immediately |
| `/refactor-clean` | `planner` ∥ `code-reviewer` → refactor → `code-reviewer` | Before / after |
| `/optimize` | `planner` (bottlenecks) ∥ `code-reviewer` (security-conscious review) | Immediately |
| `/fix-bug` | `planner` (root cause) ∥ `code-reviewer` (impact) → fix → `code-reviewer` | Before / after |
| `/document` | `general-purpose` (codebase analysis) ∥ `doc-updater` → generate → `doc-updater` (quality review) | Before / after |
| `/review-pr` | `code-reviewer` always; + `doc-updater` if docs or breaking changes; + `design-review` if UI files (`*.vue/jsx/tsx/css/scss`) changed | Immediately, parallel |
| `/update-architecture` | `doc-updater` → `.claude/architecture/{overview,components,data-flow,decisions}.md` | Immediately |
| `/update-database` | `doc-updater` → `.claude/database/{schema,erd,migrations,queries}.md` | Immediately |
| `/multi-*` (any) | `planner` ∥ `code-reviewer` | Immediately |

### `/issue-review`

**Skill**: `~/.claude/skills/issue-review-flow/SKILL.md`（必ず読み込んで従う）

1. **`code-reviewer`** (Phase 2) - ブランチ差分 `origin/<base>...HEAD` をレビュー。CRITICAL/HIGH は自動修正 → 再レビュー（最大3周）
2. **Playwright MCP** (Phase 3) - 受け入れ条件の動作確認

**Gate**: Phase 4 の手動確認でユーザ OK を得るまでマージ禁止。マージは `gh pr merge --merge --delete-branch`

## General Triggers (no slash command)

| Trigger | Agent |
|---|---|
| Feature done (3+ files), significant refactor, before commit, "review my code" | `code-reviewer` |
| Feature with 5+ steps, or "architecture" / "design" / "plan" / "計画" / "設計" | `planner` |
| Vague request ("何か作りたい", multiple interpretations) | `interviewer` |

## Parallel vs Sequential

- **Parallel**: agents analyze independent aspects (e.g. planning + security review).
- **Sequential**: the next agent depends on the previous output, or the workflow has explicit phases (TDD).

## Notification

Before launching, tell the user in one line which agents are starting and why (e.g. "🏗️ `planner` + 🔍 `code-reviewer` を並列起動"). After they finish, synthesize their findings — don't paste raw reports.

## Do NOT Auto-Launch When

- User says "no agents" / "just answer directly"
- Simple question, or the information is already available
- User is exploring/learning how a command works

## Maintenance

When adding a slash command or agent: add a row above, define timing, and update `.claude/agents/AGENTS.md` if an agent was added.
