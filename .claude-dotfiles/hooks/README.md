# Claude Code Hooks

このディレクトリには、Claude Codeのフック設定が含まれています。

## 設定ファイル

- `hooks.json`: フックの設定ファイル
- `scripts/`: フックスクリプトが格納されたディレクトリ

## 実装済みフック

### Pre-commit Hook
**ファイル**: `scripts/pre-commit-verify.js`
**トリガー**: `git commit` コマンド実行前
**機能**: コミット前の検証チェックを実行

### Post-edit Emacs Verification Hook
**ファイル**: `scripts/post-edit-emacs-verify.js`
**トリガー**: Emacs設定ファイル編集後
**対象ファイル**:
- `.emacs.d/init.el`
- `.emacs.d/elisp/` 内のファイル
- `.emacs.d/conf/` 内のファイル

**機能**:
1. 編集されたファイルの自動バックアップ作成
2. Emacs構文チェック (`emacs --batch -l`)
3. Emacsランタイムテスト
4. エラーと警告の検出・表示

## フックの有効化

フックは `.claude/hooks/hooks.json` が存在すると自動的に有効になります。

## フックのカスタマイズ

`hooks.json` を編集してフックを追加・変更できます:

```json
{
  "PreToolUse": [
    {
      "matcher": "ToolName",
      "hooks": [{
        "type": "command",
        "command": "node \"${CLAUDE_PROJECT_ROOT}/.claude/hooks/scripts/your-script.js\""
      }],
      "description": "Your hook description"
    }
  ]
}
```

## 参考リンク

- [Claude Code Hooks Documentation](https://code.claude.com/docs/en/hooks)
- [Everything Claude Code Repository](https://github.com/affaan-m/everything-claude-code)
