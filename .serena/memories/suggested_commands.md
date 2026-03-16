# Suggested Commands

## Dotfiles Management
- `make install` - Complete setup: update, deploy, init
- `make deploy` - Create symlinks to home directory
- `make init` - Run platform-specific initialization
- `make update` - Pull latest changes from remote
- `make clean` - Remove symlinks and repository
- `make list` - Display tracked dotfiles
- `make help` - Show available targets

## Development Tools
- `ls` → `lsd` (enhanced ls with icons)
- `l`, `ll` → `lsd -l` (long format)
- `la` → `lsd -a` (show hidden)
- `lla` → `lsd -la` (long + hidden)
- `lt` → `lsd --tree` (tree view)

## Git Shortcuts
- `ga` → `git add`
- `gs` → `git status`
- `gp` → `git push`
- `gc` → `git commit`
- `gco` → `git checkout`
- `gd` → `git diff`
- `gb` → `git branch`
- `gf` → `git fetch`
- `gacp "message"` - Add all, commit, and push

## System Utilities (macOS)
- Standard unix commands available
- Homebrew managed tools in `/opt/homebrew/bin`
- `brew bundle` - Install from Brewfile
- `arch` - Show architecture (arm64/x86_64)