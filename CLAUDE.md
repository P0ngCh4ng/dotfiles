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
- Basic syntax check: `emacs --batch -l ~/.emacs.d/init.el 2>&1`
- **Runtime test**: `emacs --eval "(run-with-timer 3 nil #'kill-emacs)" 2>&1` (capture stderr/stdout)
- Byte-compile validation: `emacs --batch --eval "(byte-compile-file \"~/.emacs.d/init.el\")" 2>&1`
- Package verification: `emacs --batch --eval "(progn (require 'package) (package-initialize))" 2>&1`
- **Messages buffer check**: `emacs --batch --eval "(progn (load-file \"~/.emacs.d/init.el\") (with-current-buffer \"*Messages*\" (princ (buffer-string))))" 2>&1`

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

### Package Management
- Homebrew dependencies defined in Brewfile
- Includes development tools: jq, lsd, mysql, volta, emacs
- Font and application installations via cask

## Platform Support

The repository supports macOS and Linux with platform-specific initialization:
- **macOS**: Executes scripts in `etc/init/osx/` including Homebrew setup and system defaults
- **Linux**: Runs scripts in `etc/init/linux/` for Linux-specific configuration
- **Windows**: Limited support via Cygwin detection