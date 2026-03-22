# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Structure

This is a personal dotfiles repository that manages configuration files and development environment setup through symbolic linking and automated initialization scripts.

### Key Components

- **Makefile**: Primary interface for dotfiles management with targets for installation, deployment, and cleanup
- **.zshrc**: Main shell configuration with aliases, functions, and integrations
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
- **Status**: Disabled by default in Emacs (enabled only for iTerm2 via .zshrc aliases)
- **Reason**: Emacs sessions are often already running inside cage (IN_CAGE=1). Nested cage invocations cause working directory issues and EPERM errors when writing to `.claude/projects/`
- **Usage**: Use cage only from iTerm2 terminal (aliases: `claude`, `claude-raw`)
- Toggle cage: `M-x claude-code-toggle-cage` (for testing only)
- Configure path: Customize `claude-code-projects-cage-config`

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

### Project Management
This dotfiles repository manages the **central project registry** (`projects.yml`) for all local projects on this machine.

**Responsibility**:
- Maintain `projects.yml` schema and shell functions
- Provide template (`projects.yml.example`)
- Keep port management functions in `.zshrc` up-to-date

**Available Functions** (loaded via `.zshrc`):
- `port-scan` - Display currently used ports system-wide
- `pj-info [name]` - Show project details from projects.yml
- `check-ports` - Check all projects' port assignments and availability

**File Management**:
- `projects.yml` - User's actual project list (gitignored, local only)
- `projects.yml.example` - Template for new environments (tracked in git)
- Location: `~/dotfiles/projects.yml`

**When working in dotfiles**:
- Changes to project management functions require testing with actual `projects.yml`
- Updates to shell functions must be reflected in `.zshrc`
- Template (`projects.yml.example`) should be kept simple and well-documented
- Global rules are defined in `~/.claude/rules/project-management.md`

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