# Code Style and Conventions

## Shell Scripts (Zsh/Bash)
- **Functions**: Lowercase with underscores (e.g., `auto_ls()`)
- **Aliases**: Short, memorable (e.g., `ga`, `gs`, `ll`)
- **Variables**: UPPERCASE for environment vars, lowercase for local
- **Quoting**: Always quote variable expansions: `"$VAR"`
- **Conditionals**: Prefer `[[ ]]` over `[ ]` in zsh
- **Comments**: Explanatory comments for complex logic

## Makefile
- **Targets**: Lowercase, descriptive
- **Variables**: UPPERCASE with `:=` for immediate expansion
- **Phony targets**: Declare with `.PHONY` (implicit in this repo)
- **Help text**: Echo format for `make help`
- **Indentation**: Tabs (required by Make)

## Emacs Lisp
- **UTF-8 encoding**: Always use utf-8
- **Load paths**: Add to `load-path` before requiring
- **Modular**: Separate files in `elisp/`, `conf/`, `themes/`
- **Package management**: Use package.el
- **Japanese support**: Configure for Japanese environment

## Directory Structure Conventions
- **etc/init/**: Platform-specific initialization scripts
  - `osx/`: macOS-specific (brew.sh, defaults.sh)
  - `linux/`: Linux-specific
- **.emacs.d/**: Self-contained Emacs configuration
- **Dotfiles**: Start with `.`, symlinked to `$HOME`

## Git Workflow
- Commit messages: Conventional commits style preferred
- Branch strategy: Not strictly defined (personal repo)
- Remote: origin/master (note: uses master, not main)