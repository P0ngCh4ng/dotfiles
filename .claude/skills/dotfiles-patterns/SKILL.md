---
name: dotfiles-patterns
description: Coding patterns and workflows extracted from dotfiles repository
version: 1.0.0
source: local-git-analysis
analyzed_commits: 112
repository: /Users/pongchang/dotfiles
---

# Dotfiles Repository Patterns

Personal dotfiles management system with emphasis on Emacs configuration, shell customization, and Claude Code integration.

## Commit Conventions

This repository uses a **hybrid commit style**:

### Conventional Commits (15% of commits)
Preferred format with type and optional scope:
- `feat:` / `feat(scope):` - New features (e.g., `feat(claude): add persona management system`)
- `fix:` / `fix(scope):` - Bug fixes (e.g., `fix(zsh): improve shell initialization`)
- `docs:` / `docs(scope):` - Documentation updates (e.g., `docs(emacs): add upgrade notes`)
- `chore:` / `chore(scope):` - Maintenance tasks (e.g., `chore(iterm): disable fullscreen tab bar`)
- `refactor(scope):` - Code refactoring (e.g., `refactor(emacs): migrate from leaf to use-package`)

### Common Scopes
- `claude` - Claude Code related changes (.claude/ directory)
- `emacs` - Emacs configuration (.emacs.d/)
- `zsh` - Shell configuration (.zshrc, opt.zsh)
- `iterm` - iTerm2 settings

### Informal Commits (85% of commits)
Also used for quick updates:
- `add:` - Adding new files/features
- `try:` - Experimental changes
- Direct component name (e.g., `emacs:`, `zshrc:`)
- Simple descriptions without prefix

**Recommendation**: Use conventional commits for significant changes, informal style for quick iterations.

## Repository Architecture

```
dotfiles/
├── .emacs.d/              # Emacs configuration (most active)
│   ├── init.el            # Main configuration (48 commits)
│   ├── custom.el          # Auto-generated customizations
│   ├── elisp/             # Custom elisp packages
│   ├── conf/              # Configuration modules
│   ├── themes/            # Color themes
│   └── public_repos/      # External elisp libraries
│
├── .claude/               # Claude Code integration
│   ├── agents/            # Custom agents (emacs-verifier.md)
│   ├── commands/          # Slash commands (verify-emacs.md)
│   ├── hooks/             # Git hooks and automation
│   ├── skills/            # Learned patterns
│   └── personas/          # UI generation personas
│
├── .serena/               # Serena MCP configuration
│   ├── project.yml        # Project metadata
│   └── memories/          # Session memories
│
├── etc/init/              # Platform-specific initialization
│   ├── osx/               # macOS setup scripts
│   └── linux/             # Linux setup scripts
│
├── bin/                   # Utility scripts
├── .zshrc                 # Shell configuration (26 commits)
├── opt.zsh                # Zsh options
├── Brewfile               # Homebrew dependencies
├── Makefile               # Deployment automation
├── CLAUDE.md              # Claude Code instructions
└── projects.yml.example   # Project management template
```

## Key Workflows

### 1. Emacs Configuration Development

**Pattern**: Edit → Verify → Fix → Commit

1. **Before editing**: Create backup
   ```bash
   cp ~/.emacs.d/init.el ~/.emacs.d/init.el.backup.$(date +%Y%m%d_%H%M%S)
   ```

2. **Edit configuration**: Modify `~/.emacs.d/init.el` or elisp files

3. **Clean stale byte-compiled files**:
   ```bash
   rm -f ~/.emacs.d/init.elc ~/.emacs.d/elisp/*.elc
   ```

4. **Run verification**:
   ```bash
   /verify-emacs  # Or use emacs-verifier agent
   ```

5. **Iterate until clean**: Fix all errors and warnings

6. **Optional byte-compilation** (for stable features):
   ```bash
   emacs --batch --eval "(byte-compile-file \"~/.emacs.d/elisp/FILE.el\")"
   ```

**Important Settings**:
- `load-prefer-newer t` - Prefer newer `.el` over older `.elc`
- Launch method: GUI Emacs from `/Applications/Emacs.app`

### 2. Dotfiles Deployment

**Using Makefile**:

```bash
make install    # Full setup: update + deploy + init
make deploy     # Create symlinks only
make init       # Run platform-specific initialization
make update     # Pull latest from git
make clean      # Remove all symlinks
make list       # Show tracked dotfiles
```

**Workflow**:
1. Clone repository to `~/dotfiles`
2. Run `make install`
3. Platform detection (macOS/Linux) runs appropriate scripts
4. Symlinks created: `~/dotfiles/.zshrc` → `~/.zshrc`

### 3. Project Management

**Central Registry**: `~/dotfiles/projects.yml`

**Available Commands**:
```bash
port-scan          # Display currently used ports
pj-info [name]     # Show project details
check-ports        # Check project port assignments
```

**File Management**:
- `projects.yml` - User's actual project list (gitignored)
- `projects.yml.example` - Template for new environments (tracked)

### 4. Shell Configuration

**Pattern**: `.zshrc` loads modular configurations

```bash
.zshrc
├── Loads opt.zsh          # Zsh options
├── Homebrew integration   # Auto-completion
├── Custom aliases         # ga, gs, gp, gc, gco
├── Functions              # gacp(), port-scan, pj-info
└── Auto ls on cd          # Convenience feature
```

**Key Features**:
- `lsd` as enhanced `ls` replacement
- Auto-completion with brew integration
- History management with deduplication
- Git aliases and helper functions

### 5. Claude Code Integration

**File Co-Change Pattern**:
- When editing `.emacs.d/init.el` → Often also edit `CLAUDE.md`
- When adding `.claude/agents/` → Often also update `.claude/commands/`
- When modifying `.zshrc` → Often also update `CLAUDE.md`

**Verification Automation**:
- Custom agent: `emacs-verifier` - Autonomous Emacs config verification
- Custom command: `/verify-emacs` - Manual verification workflow
- Hook: `post-edit-emacs-verify.js` - Auto-verify after editing Emacs files

## Common File Patterns

### Most Frequently Modified Files (Top 10)

| File | Commits | Purpose |
|------|---------|---------|
| `.emacs.d/init.el` | 48 | Main Emacs configuration |
| `.zshrc` | 26 | Shell configuration |
| `.gitignore` | 18 | Git ignore patterns |
| `.emacs.d/kkcrc` | 8 | Keyboard configuration |
| `todos.org` | 5 | Task tracking |
| `CLAUDE.md` | 5 | Claude Code instructions |
| `Makefile` | 4 | Deployment automation |
| `Brewfile` | 4 | Package dependencies |
| `.emacs.d/custom.el` | 4 | Auto-generated settings |
| `.zshenv` | 3 | Environment variables |

### File Co-Change Patterns

**Emacs Configuration Bundle**:
- `.emacs.d/init.el` + `.emacs.d/custom.el` (often modified together)

**Documentation Updates**:
- `CLAUDE.md` + `.claude/` subdirectories (coordinated changes)

**Shell Configuration**:
- `.zshrc` + `opt.zsh` (shell behavior changes)

## Testing & Verification

### Emacs Configuration
**Verification Commands** (all 5 must pass):
```bash
# 1. Clean old byte-compiled files
rm -f ~/.emacs.d/init.elc ~/.emacs.d/elisp/*.elc

# 2. Basic syntax check
emacs --batch -l ~/.emacs.d/init.el 2>&1

# 3. Runtime test
emacs --eval "(run-with-timer 3 nil #'kill-emacs)" 2>&1

# 4. Byte-compile validation
emacs --batch --eval "(byte-compile-file \"~/.emacs.d/init.el\")" 2>&1

# 5. Package verification
emacs --batch --eval "(progn (require 'package) (package-initialize))" 2>&1
```

**Success Criteria**:
- ZERO errors
- ZERO warnings
- Clean launch and exit

### Shell Configuration
**Manual verification**:
```bash
# Start new shell and check for errors
zsh -c 'echo "Shell OK"'

# Test key aliases
ga --help   # git add
gs          # git status
```

## Special Considerations

### Byte-Compilation Strategy
- **During development**: Keep `.elc` files deleted, rely on `load-prefer-newer t`
- **After feature completion**: Optionally byte-compile for performance
- **Never commit**: `.elc` files are gitignored

### Platform-Specific Initialization
- **macOS**: Runs scripts in `etc/init/osx/` (Homebrew, system defaults)
- **Linux**: Runs scripts in `etc/init/linux/`
- **Detection**: Automatic via Makefile

### Backup Strategy
**Automatic backups before edits**:
```bash
cp FILE FILE.backup.$(date +%Y%m%d_%H%M%S)
```

**Examples**:
- `.emacs.d/init.el.backup.20260313_135747`
- `.emacs.d/custom.el.backup.20260302`

## Quick Reference

### Common Tasks

**Deploy dotfiles**:
```bash
cd ~/dotfiles && make install
```

**Verify Emacs config**:
```bash
/verify-emacs  # or M-x claude-code-help-flow in Emacs
```

**Update dependencies**:
```bash
brew bundle --file=~/dotfiles/Brewfile
```

**Check project ports**:
```bash
check-ports
```

### Key Files to Understand

| File | Purpose | Edit Frequency |
|------|---------|----------------|
| `CLAUDE.md` | Instructions for Claude Code | High |
| `.emacs.d/init.el` | Emacs configuration | Very High |
| `.zshrc` | Shell configuration | High |
| `Makefile` | Deployment automation | Low |
| `projects.yml.example` | Project template | Low |

## Best Practices

1. **Always backup** before editing configuration files
2. **Verify immediately** after Emacs configuration changes
3. **Remove `.elc` files** during active development
4. **Use conventional commits** for significant changes
5. **Update `CLAUDE.md`** when adding new workflows
6. **Test in clean shell** after modifying `.zshrc`
7. **Document in `.claude/`** when adding custom agents/commands

---

*Generated by `/skill-create` from 112 commits on 2026-03-22*
