# Project Overview

## Purpose
Personal dotfiles repository for managing configuration files and development environment setup through symbolic linking and automated initialization scripts.

## Tech Stack
- **Shell**: Zsh with zplug plugin manager
- **Package Manager**: Homebrew (macOS)
- **Version Control**: Git
- **Editor**: Emacs with extensive custom configuration
- **Build Tool**: Make

## Platform Support
- Primary: macOS (Darwin)
- Secondary: Linux
- Limited: Windows (via Cygwin)

## Repository Structure
- **Makefile**: Primary interface for dotfiles management
- **.zshrc**: Main shell configuration with aliases and functions
- **.emacs.d/**: Complete Emacs configuration directory
- **etc/init/**: Platform-specific setup scripts (osx/, linux/)
- **Brewfile**: Homebrew package definitions
- **opt.zsh**: Comprehensive zsh option settings
- **CLAUDE.md**: Project-specific Claude Code instructions