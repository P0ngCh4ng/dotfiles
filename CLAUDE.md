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
- **Default**: Uses `cage -config ~/.config/cage/presets.yaml claude --dangerously-skip-permissions`
- Toggle cage: `M-x claude-code-toggle-cage`
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

#### Launch Method
- **Primary method**: Launch from `/Applications/Emacs.app` (macOS GUI application)
- **Not used**: Terminal emacs (`emacs -nw`) or command-line launch
- Configuration is optimized for GUI Emacs with graphical features

#### Automated Verification Workflow
When modifying Emacs configuration files (`init.el`, elisp files):
1. **Always backup first**: `cp ~/.emacs.d/init.el ~/.emacs.d/init.el.backup.$(date +%Y%m%d_%H%M%S)`
2. **After editing, run comprehensive verification**:
   - Syntax check via batch mode
   - **Runtime verification**: Actually launch Emacs and capture all errors/warnings
   - Check `*Messages*` buffer for warnings
   - Verify byte-compilation output
3. **Parse and analyze ALL warnings and errors** - not just syntax errors but also:
   - Runtime errors (undefined functions, wrong arguments, etc.)
   - Warnings (obsolete functions, deprecated features, etc.)
   - Package loading issues
   - Compilation warnings
4. **Automatically fix ALL issues** found in verification
5. **Iterate until ALL warnings and errors are resolved** - do not stop until completely clean
6. **Only confirm completion** when Emacs starts without any errors or warnings

#### Verification Commands (Execute ALL)
- **Clean old byte-compiled files**: `rm ~/.emacs.d/init.elc ~/.emacs.d/elisp/*.elc` (if they exist)
- Basic syntax check: `emacs --batch -l ~/.emacs.d/init.el 2>&1`
- **Runtime test**: `emacs --eval "(run-with-timer 3 nil #'kill-emacs)" 2>&1` (capture stderr/stdout)
- Byte-compile validation: `emacs --batch --eval "(byte-compile-file \"~/.emacs.d/init.el\")" 2>&1`
- Package verification: `emacs --batch --eval "(progn (require 'package) (package-initialize))" 2>&1`
- **Messages buffer check**: `emacs --batch --eval "(progn (load-file \"~/.emacs.d/init.el\") (with-current-buffer \"*Messages*\" (princ (buffer-string))))" 2>&1`

**IMPORTANT**: Always delete `.elc` files before verification to ensure you're testing the current `.el` source, not stale byte-compiled code.

#### Byte-Compilation Strategy
- **During development**: `load-prefer-newer t` ensures `.el` is used if newer than `.elc`
- **After feature completion**: Generate `.elc` for performance:
  ```bash
  emacs --batch --eval "(byte-compile-file \"~/.emacs.d/elisp/YOUR-FILE.el\")"
  ```
- **Best practice**: Only byte-compile stable, completed features

#### Feature-Specific Verification
When adding new commands, keybindings, or modes, verify they work correctly:

**When adding interactive commands:**
1. Verify command is interactive: `emacs --batch --eval "(progn (load-file \"~/.emacs.d/init.el\") (princ (if (commandp 'COMMAND-NAME) \"✓ Interactive\" \"✗ Not interactive\")))" 2>&1`
2. Verify autoload configured: `emacs --batch --eval "(progn (load-file \"~/.emacs.d/init.el\") (princ (if (autoloadp (symbol-function 'COMMAND-NAME)) \"✓ Autoload\" \"✗ No autoload\")))" 2>&1`
3. **Test in helm-M-x**: Actually launch Emacs and check if command appears in `helm-M-x` or `M-x`
4. **Execute the command**: Run it and verify expected behavior

**When adding keybindings:**
1. Verify binding registered: `emacs --batch --eval "(progn (load-file \"~/.emacs.d/init.el\") (princ (key-binding (kbd \"KEY-SEQUENCE\"))))" 2>&1`
2. **Test the key**: Actually press the key combination and verify it invokes the correct command
3. Check for conflicts: Verify the key isn't already bound to something important

**When adding new modes:**
1. Verify mode function exists: `emacs --batch --eval "(progn (load-file \"~/.emacs.d/init.el\") (princ (if (fboundp 'MODE-NAME) \"✓ Mode defined\" \"✗ Not defined\")))" 2>&1`
2. **Test mode activation**: Enable the mode and verify it works
3. **Test mode keybindings**: Press each key defined in the mode keymap and verify functionality
4. **Test mode hooks**: Verify hooks execute as expected
5. Verify mode-specific faces/variables are applied correctly

#### Error Handling Protocol
- **Capture BOTH stderr and stdout** (use `2>&1`) to catch all warnings/errors
- **Parse ALL messages** including:
  - Error messages (syntax, runtime, loading errors)
  - Warning messages (obsolete functions, deprecated variables)
  - Compilation warnings (unused variables, undefined functions)
  - Package-related warnings
- **Common issues to auto-fix**:
  - Missing packages → install via package-install
  - Syntax errors (quotes, parentheses) → correct syntax
  - Undefined functions → add missing `require` statements
  - Obsolete functions → replace with modern equivalents
  - Deprecated variables → update to new variable names
  - Wrong number of arguments → fix function calls
  - Unbalanced parentheses → balance properly
- **Use TodoWrite** to track: backup → edit → verify → fix ALL errors → fix ALL warnings → re-verify loop
- **CRITICAL**: Never mark task complete until Emacs runs without ANY errors OR warnings
- **CRITICAL**: "Clean" means ZERO errors and ZERO warnings - not just "no fatal errors"

#### Claude Code Integration

Claude Code provides automated tools for Emacs configuration verification:

##### Slash Command: `/verify-emacs`
Run comprehensive verification manually after editing Emacs files:
```bash
/verify-emacs
```

This command executes all 5 verification commands, parses output, and reports findings. Use this when you want to verify changes yourself.

##### Agent: `emacs-verifier`
Launch autonomous verification agent that automatically fixes issues:
```bash
# Invoke via Task tool or direct agent call
/emacs-verifier
```

The agent will:
1. Create backup automatically
2. Run all 5 verification commands
3. Parse ALL errors and warnings
4. Auto-fix common issues without asking
5. Re-verify after each fix
6. Iterate until ZERO errors and ZERO warnings
7. Provide detailed report of what was fixed

**When to use**:
- After making changes to `~/.emacs.d/init.el`
- After modifying any `~/.emacs.d/elisp/*.el` files
- When you want autonomous fix-verify iteration
- When you want guaranteed clean configuration

**Success criteria**:
- ✅ All 5 verification commands pass
- ✅ ZERO errors across all checks
- ✅ ZERO warnings across all checks
- ✅ Emacs launches successfully
- ✅ Byte-compilation completes without warnings

### Package Management
- Homebrew dependencies defined in Brewfile
- Includes development tools: jq, lsd, mysql, volta, emacs
- Font and application installations via cask

## Platform Support

The repository supports macOS and Linux with platform-specific initialization:
- **macOS**: Executes scripts in `etc/init/osx/` including Homebrew setup and system defaults
- **Linux**: Runs scripts in `etc/init/linux/` for Linux-specific configuration
- **Windows**: Limited support via Cygwin detection