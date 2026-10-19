# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Global Rules System

`~/.claude` is a symlink to `~/dotfiles/.claude`, so the rules in this repo apply to **all projects**:

```
~/.claude/rules/
├── common/    00-session-start (highest priority) · agent-automation · mcp-automation · project-management
│              bug-prevention · auto-documentation · slash-command-automation · coding-style · git-workflow · testing
└── dotfiles/  emacs-environment · database-management · verification-strategy
```

- Priority: `00-*.md` > `common/*.md`; `dotfiles/*.md` overrides common for this repo.
- Hooks (in `.claude/settings.json`): `enforce-session-start.js` (project context from `projects.yml`), `announce-managed-project.py` (ports/DB/always_on/start_command of the current project), `enforce-agent-launch.js` (reminds `code-reviewer` after Edit/Write, 5-min cooldown), plus doc-tracking and the daily dashboard.
- **Instruction size limit (150k chars total)**: keep rules terse — tables over prose, details in skills/docs. `claudeMdExcludes` in `settings.json` skips `.claude/rules/**` and `.claude/CLAUDE.md` inside dotfiles worktrees (`~/dotfiles-*/`, `~/dotfiles-worktrees/*/`) because they duplicate `~/.claude`. Edits to rules made in a worktree only take effect after merging to main.

## Repository Structure

Personal dotfiles: config files are symlinked from this repo into `$HOME`, and initialization is platform-aware.

- **Makefile** – install / deploy / cleanup interface
- **.zshrc** – shell config, aliases, functions; **db.zsh** – DB functions (sourced by .zshrc); **opt.zsh** – zsh options
- **.emacs.d/** – Emacs config (`elisp/`, `conf/`, `public_repos/`, `themes/`)
- **bin/** – `update-cage-config`, `fix-project-quarantine`, `emacs-auto-fix`, `generate-project-dashboard`, `install-dashboard-service` (see `bin/README.md`)
- **etc/init/** – platform setup (`osx/` incl. Homebrew & defaults, `linux/`; Windows only via Cygwin detection)
- **Brewfile** – Homebrew packages (jq, lsd, mysql, volta, emacs, casks)
- **projects.yml** – registry of all local projects (gitignored, local only); `projects.yml.example` is the tracked template

## Common Commands

- `make install` (update + deploy + init) · `make deploy` (symlinks; also regenerates cage config) · `make init` · `make update` · `make update-cage` · `make clean` · `make list` · `make help`
- Shell: `lsd` as `ls`; git aliases `ga` `gs` `gp` `gc` `gco`; `gacp "msg"` = add all + commit + push

## Claude Code in Emacs

Claude Code runs **inside Emacs** via `claude-code` (ELPA: core, Transient UI, MCP) and the custom `.emacs.d/elisp/claude-code-projects.el` (project shortcuts, sessions, worktrees, cage). Config lives in `.emacs.d/init.el`.

| Key / command | Action |
|---|---|
| `C-c c` | Transient menu: `c` run · `b` buffer · `p` prompt buffer · `q` close window · `Q` quit session |
| `C-c C-p` / `claude-code-select-project` | Pick a predefined project (dotfiles, pon, sokko, chatclinic, AutomationVideo, mcpCreate); `C-u` forces a new session |
| `C-c C-w` / `C-c C-l` | Switch / list sessions |
| `claude-code-add-project` · `-remove-project` · `-edit-projects` | Manage the project list |
| `claude-code-kill-session` · `-kill-all-sessions` | Kill session(s), offering worktree cleanup |
| `claude-code-toggle-cage` | Toggle cage temporarily |

Prompt buffer (`.claude-code.prompt.md`): `@ TAB` file completion · `C-c C-s` send section · `C-c C-b` send buffer · `C-c C-o` run.

Selecting a project that already has a session prompts "Switch to …" or "Create new session" (buffer `*claude:~/project<2>*`).

### Git Worktrees

Multiple sessions on one repo would fight over git, so each new session can get its own worktree:
`C-c C-p` → project → "Create new session" → "Create git worktree? y" → pick a branch (new / local / remote `origin/xxx`; `git fetch --all --prune` runs first unless `claude-code-projects-fetch-before-worktree` is nil) → `~/<project>-<branch>` is created and the session starts there.

- Commands: `claude-code-list-worktrees`, `claude-code-open-worktree`, `claude-code-cleanup-all-worktrees`
- Worktree paths are added to / removed from `~/.config/cage/presets.yaml` automatically (cage has no wildcards). If the AUTO-GENERATED marker is missing it is appended after the existing `allow:` entries.
- Uncommitted changes are protected: removal warns and requires explicit force; Emacs's startup cleanup (after 5 s) only removes orphaned cage entries, never worktree directories.
- Details, crash recovery and test scenarios: `.claude/docs/WORKTREE-QUICKSTART.md`, `.claude/docs/WORKTREE-INTEGRATION.md`.

### Cage Sandbox

- Enabled via `.zshrc` (`claude` wrapper) and `claude-code-projects-use-cage t`. Use `claude-raw` in the shell to run without cage.
- `~/.config/cage/presets.yaml` is **generated** by `bin/update-cage-config` from `projects.yml` + `.config/cage/presets.yaml.template` — never edit it by hand. Every caged Emacs launch and the dashboard's register button re-run the generator; running sessions need a restart to pick up allowlist changes.
- Allowed: all projects in `projects.yml`, plus `.claude`, `.serena`, `.npm`, `.cache`, `.config`, `.volta`, etc.
- `.claude` is a symlink, so its entry needs `eval-symlinks: true` — without it writes to `~/.claude/projects/` fail with EPERM (see `.serena/memories/troubleshooting/cage-eperm-2026-03-22.md`).
- Worktrees keep git data in the main repo's `.git`, so both launch paths pass `cage -allow-git` inside a repo (`.claude/docs/reports/2026-10-06-worktree-cage-git.md`).
- `IN_CAGE` prevents nested cage.
- `claude-code-projects-cage-excluded-dirs` (default `("~/dotfiles")`): Emacs sessions in these dirs launch **without** cage, because cage denylists `ps`/`launchctl` and dotfiles manages cage config and launchd services. Emacs launch path only.

## Project Management

This repo owns the central project registry `projects.yml`, its template, and the shell functions around it.

- **Add a project**: edit `projects.yml` → `make update-cage` (or `make deploy`).
- Per-project details (ports, DB, always_on, start_command) live only in `projects.yml`; the `announce-managed-project.py` SessionStart hook injects them into each session. Rules: `~/.claude/rules/common/project-management.md`.
- Functions: `port-scan`, `pj-info [name]`, `check-ports`, and the `db-*` family in `db.zsh` — see `~/.claude/rules/dotfiles/database-management.md` for commands, password env vars and the `databases:` schema, and `~/.claude/skills/db-management/SKILL.md` for implementation.
- When changing these functions, test against the real `projects.yml`; keep `projects.yml.example` simple and documented.

## Emacs

- Use GUI `/Applications/Emacs.app` (not `emacs -nw`). UTF-8 / Japanese environment.
- Verification: batch mode checks syntax and byte-compilation only; `:after`/`:defer` packages and their keybindings (e.g. `C-c C-p`) need a GUI test plan. "Cannot load" for lazy-loaded packages is expected.
- Tools: `/verify-emacs`, the `emacs-verifier` agent (after editing `init.el` or `elisp/*.el`). Rules: `~/.claude/rules/dotfiles/emacs-environment.md`, `verification-strategy.md`; skill: `~/.claude/skills/emacs-verification/SKILL.md`.

## Zsh

Brew-integrated completion, auto `ls` on `cd`, deduplicated history, prompt with user / arch / git status.
