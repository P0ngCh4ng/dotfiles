---
name: dotfiles-patterns
description: Coding patterns extracted from personal dotfiles repository
version: 1.0.0
source: local-git-analysis
analyzed_commits: 200
analysis_date: 2026-03-02
---

# Dotfiles Repository Patterns

## When to Activate

- Setting up new dotfiles repository
- Managing symbolic links for configuration files
- Updating shell configurations (zsh, bash)
- Modifying Emacs configuration
- Adding platform-specific initialization scripts
- Updating Brewfile dependencies
- Deploying dotfiles to new machines

## Commit Conventions

This repository uses a **mixed Japanese-English commit style** with action prefixes:

- `add` - Adding new features or configurations (most common)
- `fix` - Bug fixes and corrections
- `feat` - New features (conventional commits style)
- `change` - Modifications to existing functionality
- `update` - General updates
- `iroiro` - Japanese for "various changes" (used for multiple small changes)

### Common Commit Message Patterns

```
add [emacs] <description>     # Emacs configuration additions
add [zsh] <description>       # Zsh configuration additions
fix <component> <description> # Bug fixes
update                        # General updates
```

**Examples:**
- `add [emacs] org-roamを追加`
- `fix emacs gitignoreを修正`
- `add zsh anacondaの設定`
- `iroiro` (for miscellaneous changes)

## Code Architecture

```
dotfiles/
├── .emacs.d/              # Emacs configuration (most frequently modified)
│   ├── init.el            # Main Emacs init file (45 commits)
│   ├── custom.el          # Custom variables
│   ├── elisp/             # Custom elisp packages
│   ├── elpa/              # Package installations
│   └── kkcrc              # Input method configuration
├── .zshrc                 # Zsh configuration (23 commits)
├── .zshenv                # Zsh environment variables
├── opt.zsh                # Zsh options configuration
├── Brewfile               # Homebrew dependencies
├── Makefile               # Dotfiles management commands
├── etc/init/              # Platform-specific initialization
│   ├── init.sh            # Main initialization script
│   ├── osx/               # macOS-specific scripts
│   └── linux/             # Linux-specific scripts
└── CLAUDE.md              # Project documentation for Claude
```

## Workflows

### Adding Emacs Configuration

**Pattern detected from 45 commits to `.emacs.d/init.el`:**

1. Edit `.emacs.d/init.el` with new package or configuration
2. Often paired with `.emacs.d/kkcrc` for input method changes
3. Commit with message: `add [emacs] <feature description>`
4. Common additions: org-mode packages, LSP configurations, helm, magit

**Example sequence:**
```bash
# Edit Emacs config
vim .emacs.d/init.el

# Commit changes
git add .emacs.d/init.el
git commit -m "add [emacs] <new feature>"
```

### Updating Zsh Configuration

**Pattern detected from 23 commits to `.zshrc`:**

1. Modify `.zshrc` for aliases or functions
2. Often update `opt.zsh` simultaneously for shell options
3. May update `Brewfile` if new tools are needed
4. Commit with: `add zsh <description>` or `update`

**Common changes:**
- Adding aliases (`lsd` for `ls`, git shortcuts)
- Adding functions (auto-ls on cd, gacp for git workflow)
- Anaconda/conda configurations
- Prompt customization

### Platform-Specific Setup Updates

**Pattern: Makefile + etc/init/ changes together**

When modifying initialization scripts:
1. Update `Makefile` targets (`install`, `deploy`, `init`)
2. Modify scripts in `etc/init/osx/` or `etc/init/linux/`
3. Test with `make init` command
4. Commit: `make init コマンドを実行できるよう調整`

### Brewfile Management

**Pattern: Brewfile changes trigger broader updates**

1. Add new packages to `Brewfile`
2. Run Homebrew installation
3. May generate `Brewfile.lock.json`
4. Update `.zshrc` if new tool requires configuration
5. Commit: `add brewfileを追加` or `brewファイルの更新と、オプションファイルの実行`

## File Co-change Patterns

Files that frequently change together:

| Primary File | Often Changes With | Reason |
|--------------|-------------------|---------|
| `.emacs.d/init.el` | `.emacs.d/kkcrc` | Input method config alongside features |
| `.zshrc` | `Brewfile` | New tools require shell integration |
| `.zshrc` | `opt.zsh` | Shell options paired with aliases |
| `Makefile` | `etc/init/init.sh` | Installation workflow updates |
| `.zshrc` | `.zshenv` | Environment variable management |

## Testing and Verification

**Emacs Configuration Verification:**
- After editing `.emacs.d/init.el`, test with: `emacs --batch -l ~/.emacs.d/init.el`
- Byte-compile check for errors
- Manual launch to verify no runtime errors

**Dotfiles Deployment:**
- Use `make deploy` to create symlinks
- Use `make init` to run platform-specific setup
- Use `make list` to verify tracked files

## Language and Documentation

- **Code**: Primarily Emacs Lisp, Shell Script, Makefile
- **Comments**: Mixed Japanese and English
- **Documentation**: CLAUDE.md provides comprehensive project context
- **Commit Messages**: Mixed language, descriptive but sometimes informal ("iroiro")

## Key Insights

1. **Iterative Configuration Culture**: High commit frequency to `.emacs.d/init.el` and `.zshrc` indicates continuous refinement
2. **Japanese Development Environment**: Heavy use of Japanese input methods (mozc), org-roam with Japanese, bilingual commits
3. **macOS Primary Platform**: Most init scripts target macOS (`etc/init/osx/`), with secondary Linux support
4. **Package-First Approach**: Uses Homebrew (Brewfile), Emacs package managers (elpa, el-get), demonstrating preference for package management
5. **Documentation-Aware**: Recent addition of CLAUDE.md and .serena/ shows AI-assisted development workflow adoption

## Common Operations

```bash
# Deploy dotfiles
make install           # Full setup
make deploy           # Symlink creation only

# Manage git
gacp "message"        # Add all, commit, push in one command
gs                    # git status
ga                    # git add
gco                   # git checkout

# Development tools
lsd                   # Enhanced ls replacement
```

---

*Generated by /skill-create on 2026-03-02*
*Analyzed 200 commits from dotfiles repository*
