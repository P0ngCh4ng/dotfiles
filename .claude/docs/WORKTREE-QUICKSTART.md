# Git Worktree Integration - Quick Start

## すぐに使える！5分でわかるWorktree統合

### 🚀 有効化する方法

```elisp
;; Emacs再起動（最も確実）
C-x C-c
;; Emacs再起動

;; または手動リロード
M-x load-file RET ~/.emacs.d/elisp/claude-code-projects.el RET
```

### 📝 基本的な使い方

**新規worktreeでセッション起動**:
```elisp
C-c C-p           # プロジェクト選択
→ dotfiles        # プロジェクト選ぶ
→ Create new session
→ Create git worktree? y
→ Branch name: feature-xyz
→ セッション起動 ✅
```

**セッション終了 + worktree削除**:
```elisp
M-x claude-code-kill-session
→ Kill session? y
→ Remove worktree? y
→ 削除完了 ✅
```

### ⚠️ 未コミット変更がある場合

```elisp
M-x claude-code-kill-session
→ "⚠️ WARNING: Has uncommitted changes!"
→ "Force remove? n"  # n を選択
→ worktree保持 ✅  # 変更を失わない
```

### 🧹 クリーンアップ（PC クラッシュ後）

**自動**: Emacs起動5秒後に実行
- cage設定から孤立エントリを削除
- worktreeディレクトリは残る（安全）

**手動**:
```elisp
M-x claude-code-cleanup-all-worktrees
→ 孤立worktree一覧表示
→ 未コミット変更があれば警告
→ Clean up? y
→ Force remove? n  # 未コミット変更があるものはスキップ
```

### 📋 新しいコマンド一覧

```elisp
M-x claude-code-list-worktrees        # worktree一覧
M-x claude-code-open-worktree         # 既存worktreeを開く
M-x claude-code-cleanup-all-worktrees # 孤立worktree削除
M-x claude-code-kill-session          # セッション終了
```

### ✅ テスト手順（3分）

1. **Worktree作成**:
   ```elisp
   C-c C-p → dotfiles → Create new session
   → Create git worktree? y
   → Branch name: test-worktree-demo
   ```

2. **未コミット変更を作成**:
   ```bash
   cd ~/dotfiles-test-worktree-demo
   echo "test" > test.txt
   ```

3. **削除保護を確認**:
   ```elisp
   M-x claude-code-kill-session
   → "⚠️ WARNING: Has uncommitted changes!" が表示される
   → n を選択
   → worktreeが残る ✅
   ```

4. **クリーンアップ**:
   ```bash
   cd ~/dotfiles-test-worktree-demo
   git add . && git commit -m "test"
   ```
   ```elisp
   M-x claude-code-kill-session
   → Remove worktree? y
   → 削除成功 ✅
   ```

### 🎯 よくある使い方

**複数機能を同時開発**:
```
Session 1: ~/dotfiles (main) - バグ修正
Session 2: ~/dotfiles-feature-a (feature-a) - 新機能A
Session 3: ~/dotfiles-feature-b (feature-b) - 新機能B
→ git操作が競合しない ✅
```

**PRレビュー中に別作業**:
```
Session 1: ~/dotfiles (main) - 新しい作業
Session 2: ~/dotfiles-review-pr-123 (pr-123) - レビュー・確認
→ mainを汚さずにPRを確認できる ✅
```

### 🔧 トラブルシューティング

**Q: "Operation not permitted" エラー**
```bash
# cage設定を確認
cat ~/.config/cage/presets.yaml | grep AUTO-GENERATED

# なければ自動追加されるはず（フォールバック処理）
# それでもダメなら：
make deploy  # cage設定を再生成
```

**Q: Worktreeが削除できない**
```elisp
# 未コミット変更を確認
cd ~/dotfiles-worktree-name
git status

# コミットするか、強制削除
M-x claude-code-kill-session
→ Force remove? y  # 本当に削除する場合のみ
```

**Q: cage設定にゴミが残る**
```elisp
# 自動クリーンアップ実行
M-x claude-code-projects--cleanup-orphaned-worktrees

# または、存在しないパスを手動削除
vim ~/.config/cage/presets.yaml
```

### 📚 詳細ドキュメント

- 完全ドキュメント: `.claude/docs/WORKTREE-INTEGRATION.md`
- ユーザーマニュアル: `CLAUDE.md` (Worktree Integration セクション)

### 🔒 安全機能

- ✅ 未コミット変更を自動検出
- ✅ 削除時に警告表示
- ✅ 自動クリーンアップはcage設定のみ（ディレクトリは残す）
- ✅ force削除には明示的な確認が必要
- ✅ Cage sandboxが有効（セキュリティ維持）

---

**Happy Coding with Worktree! 🎉**
