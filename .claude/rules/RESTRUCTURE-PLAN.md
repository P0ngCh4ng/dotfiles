# Rules Restructure Plan

**Date**: 2026-03-27
**Goal**: Everything-Claude-Code風の階層構造に再構成

## 新しい構造

```
~/.claude/rules/
├── common/                           # 全プロジェクト共通（必須）
│   ├── 00-session-start.md          # ⭐ 新規: セッション開始時の必須動作（最優先）
│   ├── agent-automation.md          # 移動
│   ├── project-management.md        # 移動
│   ├── bug-prevention.md            # 移動
│   ├── auto-documentation.md        # 移動
│   ├── slash-command-automation.md  # 移動
│   ├── coding-style.md              # 既存（保持）
│   ├── git-workflow.md              # 既存（保持）
│   └── testing.md                   # 既存（保持）
└── dotfiles/                         # dotfiles プロジェクト専用
    ├── emacs-environment.md         # 移動
    ├── database-management.md       # 移動
    └── verification-strategy.md     # 移動
```

**削除するファイル**:
- `project-specific-rules.md` - 自動生成ファイル（~/dotfiles/から生成される）

## Hooks Structure

```
~/.claude/hooks/
├── hooks.json                        # 更新
└── scripts/
    ├── check-project-docs.js        # 既存（保持）
    ├── track-doc-updates.js         # 既存（保持）
    ├── enforce-session-start.js     # ⭐ 新規
    └── enforce-agent-launch.js      # ⭐ 新規
```

## Migration Steps

1. ✅ Backup created: `~/.claude/backups/rules-20260327-170057/`
2. Create new structure directories
3. Move files to appropriate locations
4. Create new `00-session-start.md` (highest priority)
5. Create hook scripts
6. Update `hooks.json`
7. Test session start automation
8. Document changes in dotfiles/CLAUDE.md

## Priority System

**File naming convention for priority**:
- `00-xxx.md` - Critical, highest priority
- `01-xxx.md` - High priority
- `xx-xxx.md` - Normal priority

Common rules < Language/Project-specific rules (language-specific overrides common)
