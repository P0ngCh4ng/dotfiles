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

### Package Management
- Homebrew dependencies defined in Brewfile
- Includes development tools: jq, lsd, mysql, volta, emacs
- Font and application installations via cask

## Platform Support

The repository supports macOS and Linux with platform-specific initialization:
- **macOS**: Executes scripts in `etc/init/osx/` including Homebrew setup and system defaults
- **Linux**: Runs scripts in `etc/init/linux/` for Linux-specific configuration
- **Windows**: Limited support via Cygwin detection