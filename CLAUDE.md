# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Structure

This is a personal dotfiles repository that manages configuration files and development environment setup through symbolic linking and automated initialization scripts.

### Key Components

- **Makefile**: Primary interface for dotfiles management with targets for installation, deployment, and cleanup
- **.zshrc**: Main shell configuration with aliases, functions, and integrations
- **db.zsh**: Database management functions (sourced by .zshrc)
- **.emacs.d/**: Complete Emacs configuration directory with custom elisp packages
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
  - `.config/cage/presets.yaml`: Main configuration with `eval-symlinks: true` for `.claude`
- **Important**: `.claude` is a symlink to `dotfiles/.claude` - requires `eval-symlinks: true`
- **Allowed paths** (in presets.yaml):
  - All projects from `projects.yml` (dotfiles, pon, SOKKO, ChatClinic, onlinemedic, hojocon)
  - Global directories: `.claude`, `.serena`, `.npm`, `.cache`, `.config`, `.volta`, etc.
- **Toggle**: `M-x claude-code-toggle-cage` to enable/disable cage temporarily
- **Nested cage detection**: Automatically prevents nested cage execution via `IN_CAGE` environment variable

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
M-x claude-code-add-project       # Add current directory to list
M-x claude-code-remove-project    # Remove project from list
M-x claude-code-edit-projects     # Customize project list
```

**Session Management Commands**:
```elisp
M-x claude-code-switch-session    # Switch between sessions (C-c C-w)
M-x claude-code-list-sessions     # Show all active sessions (C-c C-l)
M-x claude-code-kill-all-sessions # Kill all sessions
M-x claude-code-toggle-cage       # Toggle cage on/off
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
  - `~/.claude/rules/project-specific-rules.md` - Detailed rules for each project
  - `~/.claude/rules/database-management.md` - Database operations and workflows
- **Implementation documentation**: `~/.claude/skills/db-management/SKILL.md`

**Important**: When updating `projects.yml`, also update `~/.claude/rules/project-specific-rules.md` to keep them in sync.

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