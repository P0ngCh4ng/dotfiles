# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 🚨 CRITICAL: Global Rules System

**Last Updated**: 2026-03-27 - Restructured to Everything-Claude-Code architecture

**Global rules are now ENFORCED by hooks and file structure:**

```
~/.claude/rules/
├── common/                           # All projects (highest priority)
│   ├── 00-session-start.md          # ⚠️ MANDATORY session start protocol
│   ├── agent-automation.md
│   ├── mcp-automation.md            # MCP tool auto-use rules
│   ├── project-management.md
│   ├── bug-prevention.md
│   ├── auto-documentation.md
│   ├── slash-command-automation.md
│   ├── coding-style.md
│   ├── git-workflow.md
│   └── testing.md
└── dotfiles/                         # Dotfiles-specific rules
    ├── emacs-environment.md
    ├── database-management.md
    └── verification-strategy.md
```

**Enforcement Mechanisms:**

1. **SessionStart Hook** (`~/.claude/hooks/scripts/enforce-session-start.js`)
   - Automatically loads project context from `~/dotfiles/projects.yml`
   - Displays project info at every session start
   - Shows port assignments, databases, tech stack

2. **PostToolUse Hook** (`~/.claude/hooks/scripts/enforce-agent-launch.js`)
   - Reminds to launch `code-reviewer` after Edit/Write
   - Cooldown: 5 minutes between reminders
   - Enforces agent auto-launch rules

3. **Priority System**
   - `00-xxx.md` files = Highest priority (critical)
   - `common/*.md` = General rules (all projects)
   - `dotfiles/*.md` = Project-specific rules (override common)

**See**: `~/.claude/rules/RESTRUCTURE-PLAN.md` for migration details

## Repository Structure

This is a personal dotfiles repository that manages configuration files and development environment setup through symbolic linking and automated initialization scripts.

### Key Components

- **Makefile**: Primary interface for dotfiles management with targets for installation, deployment, and cleanup
- **.zshrc**: Main shell configuration with aliases, functions, and integrations
- **db.zsh**: Database management functions (sourced by .zshrc)
- **.emacs.d/**: Complete Emacs configuration directory with custom elisp packages
- **bin/**: Automation scripts
  - `update-cage-config` - Auto-generate cage configuration from projects.yml
  - `fix-project-quarantine` - Remove macOS quarantine attributes
  - `emacs-auto-fix` - Emacs configuration validation and auto-fixing
- **etc/init/**: Platform-specific setup scripts for macOS and Linux
- **Brewfile**: Homebrew package definitions for macOS dependencies
- **opt.zsh**: Comprehensive zsh option settings for shell behavior
- **projects.yml**: Central registry for all local projects on this machine (gitignored, local only)

### Architecture

The dotfiles system uses a symbolic linking approach where configuration files are deployed from this repository to the home directory. The initialization process is platform-aware, executing different setup scripts based on the detected operating system.

## Common Commands

### Dotfiles Management
- `make install` - Complete setup: update repository, deploy symlinks, run initialization
- `make deploy` - Create symlinks to home directory for all dotfiles
- `make init` - Run platform-specific initialization scripts
- `make update` - Pull latest changes from remote repository
- `make update-cage` - Update cage config from projects.yml (auto-runs on deploy)
- `make clean` - Remove all symlinks and the repository
- `make list` - Display all tracked dotfiles
- `make help` - Show available make targets

### Development Environment
- Shell uses `lsd` as enhanced `ls` replacement
- Git aliases include: `ga` (add), `gs` (status), `gp` (push), `gc` (commit), `gco` (checkout)
- `gacp()` function: add all, commit with message, and push in one command

### Claude Code in Emacs
This environment uses Claude Code **exclusively within Emacs** (not terminal).

**Package Setup**:
- **Official package**: `claude-code` (from ELPA) - Provides core functionality, Transient UI, MCP integration
- **Custom extension**: `claude-code-projects` - Adds predefined project shortcuts

**Quick Start**:
```elisp
C-c c              # Open Claude Code Transient menu (main interface)
C-c C-p            # Quick select from predefined projects
C-c C-w            # Switch between active sessions
C-c C-l            # List all active sessions
```

**Cage Integration**:
- **Status**: ✅ **ENABLED** with symlink resolution fix
- **Configuration**:
  - `.zshrc` (line 194): Uses cage wrapper for sandboxing
  - `.emacs.d/elisp/claude-code-projects.el` (line 39): `claude-code-projects-use-cage t`
  - `.config/cage/presets.yaml`: Auto-generated from `projects.yml` (DO NOT edit manually)
  - **Template**: `.config/cage/presets.yaml.template` - Base configuration
  - **Generator**: `bin/update-cage-config` - Reads projects.yml and generates config
- **Important**: `.claude` is a symlink to `dotfiles/.claude` - requires `eval-symlinks: true`
- **Dynamic Project Management**:
  - `projects.yml` is the single source of truth for all projects
  - `make update-cage` - Regenerate cage config from projects.yml
  - `make deploy` - Automatically updates cage config
  - Adding a new project: Update `projects.yml` → Run `make update-cage`
- **Allowed paths** (auto-generated from projects.yml):
  - All projects: dotfiles, pon, SOKKO, ChatClinic, onlinemedic, hojocon, AutomationVideo
  - Global directories: `.claude`, `.serena`, `.npm`, `.cache`, `.config`, `.volta`, etc.
- **Toggle**: `M-x claude-code-toggle-cage` to enable/disable cage temporarily
- **Nested cage detection**: Automatically prevents nested cage execution via `IN_CAGE` environment variable
- **Per-directory exclusion**: `claude-code-projects-cage-excluded-dirs` (default: `("~/dotfiles")`) — sessions started (via `C-c C-p`/`C-c c`) in this directory or any subdirectory always launch *without* cage, regardless of `claude-code-projects-use-cage`. Reason: cage denylists `ps`/`launchctl` (XPC-based tools), but dotfiles is the project that manages cage's own config and installs launchd services, so it regularly needs exactly those tools. Applies only to the Emacs launch path (`claude-code-projects--get-command`); the `.zshrc` `claude` alias is unaffected — use `claude-raw` there for the same effect outside Emacs.

**Main Workflow (Transient Menu - `C-c c`)**:
```
c - Run Claude Code       # Start session in current project
b - Switch to buffer      # Switch to Claude Code vterm
p - Open prompt buffer    # Edit prompts in markdown
q - Close window          # Close Claude Code window
Q - Quit session          # Terminate Claude Code session
```

**Prompt Buffer** (`.claude-code.prompt.md`):
```elisp
@ TAB              # Complete file paths
C-c C-s            # Send section at point
C-c C-b            # Send entire buffer
C-c C-o            # Run Claude Code
```

**Predefined Projects** (via `claude-code-projects`):
- dotfiles
- pon
- sokko
- chatclinic
- AutomationVideo
- mcpCreate

**Project Management Commands**:
```elisp
M-x claude-code-select-project    # Select from predefined list
C-u M-x claude-code-select-project # Force create new session (skip prompt)
M-x claude-code-add-project       # Add current directory to list
M-x claude-code-remove-project    # Remove project from list
M-x claude-code-edit-projects     # Customize project list
```

**Multiple Sessions per Project**:
- When selecting a project with existing sessions, you'll be prompted:
  - "Switch to: *claude:~/project*" - Switch to existing session
  - "Create new session" - Start new session (buffer name: `*claude:~/project<2>*`)
- Use prefix argument `C-u` to skip prompt and force new session creation

**Git Worktree Integration** (避免git操作冲突):
- **问题**: 同じプロジェクトで複数セッションを立ち上げると、git操作が競合する
- **解決策**: git worktree を使って、ブランチごとに別ディレクトリで作業
- **Cage対応**: worktree作成時に自動的に`~/.config/cage/presets.yaml`に追加、削除時に自動削除

**📚 詳細ドキュメント**:
- **クイックスタート**: `.claude/docs/WORKTREE-QUICKSTART.md` - 5分でわかる使い方
- **完全ドキュメント**: `.claude/docs/WORKTREE-INTEGRATION.md` - 実装詳細・トラブルシューティング

**Worktree作成方法**:
1. `C-c C-p` (claude-code-select-project) でプロジェクト選択
2. "Create new session" を選択
3. "Create git worktree for this session? (y/n)" → `y`
4. ブランチ名を入力（新規 or 既存）
5. 自動的に `~/project-name-branch` ディレクトリが作成される
6. そのディレクトリでClaude Codeセッションが起動

**例**:
```
メインプロジェクト: ~/dotfiles (main ブランチ)
Worktree 1:         ~/dotfiles-feature-a (feature-a ブランチ)
Worktree 2:         ~/dotfiles-bugfix-123 (bugfix-123 ブランチ)
→ 各セッションが独立した実ファイルで作業できる
```

**Worktree管理コマンド**:
```elisp
M-x claude-code-list-worktrees       # プロジェクトのworktree一覧を表示
M-x claude-code-open-worktree        # 既存worktreeでセッションを開く
M-x claude-code-cleanup-all-worktrees # 全プロジェクトの孤立worktreeを削除
M-x claude-code-kill-session         # 現在のセッションを終了（worktreeも削除可能）
```

**Session Management Commands**:
```elisp
M-x claude-code-switch-session    # Switch between sessions (C-c C-w)
M-x claude-code-list-sessions     # Show all active sessions (C-c C-l)
M-x claude-code-kill-session      # Kill current session (with worktree cleanup)
M-x claude-code-kill-all-sessions # Kill all sessions (with worktree cleanup)
M-x claude-code-toggle-cage       # Toggle cage on/off
```

**Cage設定の自動管理**:
- Worktree作成時: `~/.config/cage/presets.yaml`に自動追加
  ```yaml
  allow:
    - "/Users/pongchang/dotfiles-feature-a"  # worktree (auto-added)
  ```
- Worktree削除時: セッション終了時に自動削除
- **注意**: cageはワイルドカード非対応のため、個別パス管理が必要

**クラッシュ対策（自動クリーンアップ）**:
- **問題**: PCの電源が切れた場合、worktreeディレクトリとcage設定が残る
- **解決策**:
  1. **起動時自動クリーンアップ**: Emacs起動5秒後に孤立したcageエントリを削除
     - ⚠️ **安全**: cage設定のみ削除、worktreeディレクトリは残す
     - 未コミット変更は保護される
  2. **手動クリーンアップ**: `M-x claude-code-cleanup-all-worktrees`
     - 全プロジェクトのworktreeをチェック
     - アクティブセッションがないworktreeを検出
     - 未コミット変更がある場合は ⚠️ 警告を表示
     - force削除するかどうかを確認

**未コミット変更の保護**:
```
セッション終了時:
  ↓
Worktree削除確認
  ↓
未コミット変更をチェック
  ↓
【変更あり】⚠️ WARNING: Has uncommitted changes!
  → force削除するか確認
【変更なし】通常削除
```

**安全機能**:
- ✅ 自動クリーンアップはcage設定のみ（worktreeディレクトリは削除しない）
- ✅ 手動削除時は未コミット変更を警告
- ✅ force削除には明示的な確認が必要
- ✅ デフォルトで`git worktree remove`は未コミット変更があると失敗

**ベストプラクティス**:
- ✅ **複数機能を同時開発**: 各機能でworktreeを作成
- ✅ **PRレビュー中に別作業**: mainで作業しながら、別ブランチをworktreeで確認
- ✅ **長期実験ブランチ**: worktreeで実験的変更を維持
- ⚠️ **調査のみなら不要**: 読み取り専用ならworktreeなしでもOK
- 🔒 **セキュリティ維持**: worktreeでもcageサンドボックスが有効

**フォールバック処理（AUTO-GENERATEDマーカーがない場合）**:
- **問題**: 手動編集でマーカーが削除された場合
- **解決策**: 自動的にマーカーを追加してworktreeパスを登録
- **動作**:
  1. マーカーを探す
  2. 見つからない → ファイル末尾にマーカーとworktreeパスを追加
  3. インデントは既存の`allow:`エントリに合わせる
- **エラーハンドリング**: `allow:`セクションが見つからない場合はエラーメッセージ

**テストシナリオ（Emacs内で実行）**:

1. **Worktree作成テスト**:
   ```elisp
   C-c C-p → dotfiles → Create new session
   → "Create git worktree? y"
   → Branch name: test-feature

   確認:
   - ~/dotfiles-test-feature ディレクトリが作成される
   - ~/.config/cage/presets.yaml に追加される
   ```

2. **未コミット変更保護テスト**:
   ```bash
   # worktreeで変更を作成
   cd ~/dotfiles-test-feature
   echo "test" > test.txt

   # Emacsで削除試行
   M-x claude-code-kill-session
   → "Remove worktree? ⚠️ WARNING: Has uncommitted changes!"
   → n を選択 → worktreeが保持される ✅
   ```

3. **クリーンアップテスト**:
   ```elisp
   # Emacsを強制終了してworktreeを残す
   M-x claude-code-cleanup-all-worktrees

   → Found 1 orphaned worktree:
     dotfiles: ~/dotfiles-test-feature ⚠️ HAS UNCOMMITTED CHANGES
   → Clean up? y
   → Force remove? n
   → スキップされる ✅
   ```

4. **自動クリーンアップテスト**:
   ```elisp
   # Emacs再起動
   # 5秒後に自動実行
   → "Cleaned up 1 orphaned worktree(s) from cage config"
   # cage設定から削除、ディレクトリは残る ✅
   ```

**Workflow Example**:
1. `C-c C-p` → Select "dotfiles"
2. `C-c c` → Opens Transient menu
3. `p` → Open prompt buffer
4. Type request with `@` file completion
5. `C-c C-b` → Send to Claude Code
6. Work in vterm buffer with Claude

**Files**:
- Package: `.emacs.d/elpa/claude-code-*/`
- Extension: `.emacs.d/elisp/claude-code-projects.el`
- Config: `.emacs.d/init.el` (lines 425-443)

#### Troubleshooting

**EPERM Error: "operation not permitted" when writing to `.claude/projects/`**

**Symptoms**:
```
Error: EPERM: operation not permitted, open '/Users/pongchang/.claude/projects/-Users-pongchang-pon/[uuid].jsonl'
```

**Root Cause (RESOLVED - 2026-03-22)**:
`.claude` is a symlink to `dotfiles/.claude`. cage requires `eval-symlinks: true` to allow writes to the actual path.

**Solution**:
Add `eval-symlinks: true` to `.config/cage/presets.yaml`:

```yaml
presets:
  claude-code:
    allow:
      - path: "/Users/pongchang/.claude"
        eval-symlinks: true  # Required for symlinks
```

**Verification**:
```bash
# Test cage with symlink resolution
cd ~/pon
cage -config "$HOME/.config/cage/presets.yaml" -preset claude-code claude --dangerously-skip-permissions

# Should work without EPERM errors
```

**Related Documentation**:
- See `.serena/memories/troubleshooting/cage-eperm-2026-03-22.md` for investigation details

### Project Management
This dotfiles repository manages the **central project registry** (`projects.yml`) for all local projects on this machine.

**Responsibility**:
- Maintain `projects.yml` schema and shell functions
- Provide template (`projects.yml.example`)
- Keep port management and database management functions in `.zshrc` up-to-date
- Auto-generate cage configuration from `projects.yml`

**Adding a New Project**:
1. Edit `projects.yml` - Add project with path, ports, description, tech stack
2. Run `make update-cage` - Auto-updates cage permissions (or `make deploy`)
3. Update `~/.claude/rules/project-specific-rules.md` - Add project-specific rules
4. Done! Cage sandbox now allows access to the new project

**Project-Specific Rules**:
- **Global rules**: `~/.claude/rules/project-management.md` - High-level project management strategy
- **Project details**: `~/.claude/rules/project-specific-rules.md` - Each project's DB, ports, workflows
- All projects use **グローバル設定** from `~/.claude/rules/` (no per-project `.claude/rules/` needed)

**Available Functions** (loaded via `.zshrc`):
- `port-scan` - Display currently used ports system-wide
- `pj-info [name]` - Show project details from projects.yml (includes database count)
- `check-ports` - Check all projects' port assignments and availability

**Database Management Functions**:

*Core Operations*:
- `db-list [project]` - List all databases for a project with connection status
- `db-info [project] [db-name]` - Show detailed database information
- `db-connect [project] [db-name]` - Connect to a database (MySQL/PostgreSQL)

*Backup & Restore*:
- `db-backup [project] [db-name]` - Create timestamped backup (gzip compressed)
- `db-restore [project] [db-name] [backup-file]` - Restore from backup (with confirmation)
  - Automatic cleanup of old backups based on retention policy

*Docker Management*:
- `db-status [project]` - Show all database container statuses
- `db-start [project] [db-name]` - Start database containers (supports docker-compose)
- `db-stop [project] [db-name]` - Stop database containers

*Security & Testing*:
- `db-set-password [project] [db-name]` - Set password securely (hidden input)
- `db-test-connection [project] [db-name]` - Test database connectivity

**Database Configuration** (in `projects.yml`):
```yaml
databases:
  - name: main                    # Database identifier
    type: postgresql              # mysql | postgresql | sqlite | mongodb | redis
    host: localhost               # or docker container name
    port: 5432                    # optional (uses DB default if omitted)
    database: example_dev         # database name
    user: example_user            # database user
    # Password via env var: PROJECT_DB_MAIN_PASSWORD
    docker:
      container: example-postgres # Docker container name
      compose_file: docker-compose.yml  # optional
    backup:
      enabled: true               # Enable automatic backups
      retention_days: 7           # Keep backups for N days
      path: ~/backups/example     # optional backup path
```

**Password Management**:
- Convention: `${PROJECT}_DB_${DB_NAME}_PASSWORD` (uppercase)
- Example: `EXAMPLE_PROJECT_DB_MAIN_PASSWORD=secret123`
- Set in `~/.zshenv` or `~/.zprofile` for persistence

**Supported Database Types**:
- MySQL (port 3306) - via `mysql` client
- PostgreSQL (port 5432) - via `psql` client
- Redis (port 6379) - future support
- MongoDB (port 27017) - future support
- SQLite - future support

**Docker Integration**:
- Automatically detects running containers
- Shows container status in `db-list` and `db-info` (✅/❌)
- Uses `docker exec` for connections when container is running

**File Management**:
- `projects.yml` - User's actual project list (gitignored, local only)
- `projects.yml.example` - Template for new environments (tracked in git)
- Location: `~/dotfiles/projects.yml`

**When working in dotfiles**:
- Changes to project management functions require testing with actual `projects.yml`
- Port management functions are in `.zshrc`
- **Database management functions are in `db.zsh`** (sourced by .zshrc)
- Template (`projects.yml.example`) should be kept simple and well-documented
- **Global rules** (apply to ALL projects):
  - `~/.claude/rules/project-management.md` - High-level project management strategy
  - `~/.claude/rules/project-specific-rules.md` - **Auto-generated** from `projects.yml`
  - `~/.claude/rules/database-management.md` - Database operations and workflows
- **Implementation documentation**: `~/.claude/skills/db-management/SKILL.md`

**Auto-Generated Global Rules**:
- `~/.claude/rules/project-specific-rules.md` is **automatically generated** from `projects.yml`
- Running `make deploy` or `make deploy-project-rules` updates this file
- **DO NOT edit this file manually** - edit `projects.yml` instead
- The global rules file is loaded by Claude Code in **ALL projects**

**Key Features**:
- ✅ All passwords via environment variables (secure, not in shell history)
- ✅ Automatic Docker detection and container management
- ✅ Backup rotation with configurable retention
- ✅ Interactive restore with confirmation prompts
- ✅ docker-compose integration for container lifecycle
- ✅ Connection testing with troubleshooting tips

## Configuration Details

### Zsh Configuration
- Auto-completion with brew integration
- Auto `ls` on directory changes
- Extensive history management with deduplication
- Custom prompt showing username, architecture, and git status

### Emacs Configuration
- Modular configuration loading from `elisp/`, `conf/`, `public_repos/`, `themes/`
- UTF-8 encoding setup with Japanese language environment
- Custom load-path management for extensibility

**Environment**: See `~/.claude/rules/emacs-environment.md` for details
- **Primary method**: Launch from `/Applications/Emacs.app` (macOS GUI application)
- **Not used**: Terminal emacs (`emacs -nw`) or command-line launch
- Configuration is optimized for GUI Emacs with graphical features

#### Emacs Verification

**Complete documentation available at**:
- **Rules**: `~/.claude/rules/emacs-environment.md` - Environment detection, batch mode limitations
- **Rules**: `~/.claude/rules/verification-strategy.md` - When to use which verification method
- **Skills**: `~/.claude/skills/emacs-verification/SKILL.md` - Concrete verification commands

**Critical Understanding**:
- **Batch mode limitations**: Packages with `:after` or `:defer` won't load in batch mode
- **"Cannot load" messages**: For lazy-loaded packages are EXPECTED and NORMAL, not errors
- **GUI testing required**: For lazy-loaded features like `C-c C-p` (claude-code-projects)
- **Environment detection**: Auto-detect `/Applications/Emacs.app/Contents/MacOS/Emacs` vs `emacs` command

**Verification Workflow**:
1. Backup first
2. Run batch mode checks (syntax, byte-compile)
3. Understand what batch mode **cannot** verify (lazy-loaded features)
4. Create GUI test plan for features that need manual testing
5. Fix **actual** errors (not lazy-load messages)
6. Iterate until clean

**Tools**:
- **Slash Command**: `/verify-emacs` - Run verification with environment detection
- **Agent**: `emacs-verifier` - Autonomous verification with auto-fixing

**When to use emacs-verifier**:
- After editing `~/.emacs.d/init.el` or `~/.emacs.d/elisp/*.el`
- When you want automated fix-verify iteration
- When you need guaranteed clean configuration (zero actual errors/warnings)

**Success criteria**:
- ✅ Zero **actual** errors (ignoring lazy-load messages)
- ✅ Zero **actual** warnings (ignoring lazy-load messages)
- ✅ Batch mode checks pass
- ✅ GUI test plan created for lazy-loaded features

### Package Management
- Homebrew dependencies defined in Brewfile
- Includes development tools: jq, lsd, mysql, volta, emacs
- Font and application installations via cask

## Platform Support

The repository supports macOS and Linux with platform-specific initialization:
- **macOS**: Executes scripts in `etc/init/osx/` including Homebrew setup and system defaults
- **Linux**: Runs scripts in `etc/init/linux/` for Linux-specific configuration
- **Windows**: Limited support via Cygwin detection