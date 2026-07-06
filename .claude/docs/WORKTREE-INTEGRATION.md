# Git Worktree Integration for Claude Code

**作成日**: 2026-04-13
**目的**: 同じプロジェクトで複数のClaude Codeセッションを安全に実行

## 概要

同じプロジェクトで複数のClaude Codeセッションを立ち上げると、git操作が競合する問題を解決するため、git worktreeを統合しました。

## 実装した機能

### 1. Git Worktree自動作成

**機能**:
- 新規セッション作成時にworktreeを作成可能
- ブランチ名から自動的にディレクトリ名を生成
- 例: `feature-a` → `~/dotfiles-feature-a`

**使い方**:
```elisp
C-c C-p → プロジェクト選択 → Create new session
→ "Create git worktree? y"
→ Branch name: feature-a
→ ~/dotfiles-feature-a でセッション起動
```

**実装ファイル**:
- `.emacs.d/elisp/claude-code-projects.el:113-143`
- 関数: `claude-code-projects--create-worktree`

### 2. Cage設定の動的管理

**問題**: cageはワイルドカード非対応のため、worktreeディレクトリへの書き込み権限がない

**解決策**:
- Worktree作成**前**に`~/.config/cage/presets.yaml`にパスを追加
- 作成失敗時は自動ロールバック
- セッション終了時に自動削除

**動作フロー**:
```
1. cage設定にworktreeパスを追加
   ↓
2. git worktree add でworktree作成
   ↓
3. 【成功】新規セッション起動（最新cage設定を使用）
   【失敗】cage設定から削除（ロールバック）
```

**実装ファイル**:
- `.emacs.d/elisp/claude-code-projects.el:82-123`
- 関数: `claude-code-projects--add-worktree-to-cage`
- 関数: `claude-code-projects--remove-worktree-from-cage`

### 3. 未コミット変更の保護

**問題**: Worktree削除時に未コミット変更が失われる

**解決策**: 3層の安全機能
1. `git status --porcelain`で未コミット変更を検出
2. 削除プロンプトで⚠️警告表示
3. force削除には明示的な確認が必要

**動作例**:
```
セッション終了
  ↓
"Remove worktree at ~/dotfiles-feature-a?"
  ↓
未コミット変更をチェック
  ↓
【変更あり】
  "⚠️ WARNING: Has uncommitted changes!"
  → "Force remove?" (y/n)
  → n → worktree保持 ✅

【変更なし】
  通常削除 ✅
```

**実装ファイル**:
- `.emacs.d/elisp/claude-code-projects.el:158-188`
- 関数: `claude-code-projects--worktree-has-changes`
- 関数: `claude-code-projects--remove-worktree`

### 4. クラッシュ対策（自動クリーンアップ）

**問題**: PCクラッシュ時、worktreeディレクトリとcage設定が残る

**解決策**:
1. **起動時自動クリーンアップ**: Emacs起動5秒後に実行
   - cage設定から存在しないworktreeパスを削除
   - worktreeディレクトリは削除しない（未コミット変更を保護）
2. **手動クリーンアップ**: `M-x claude-code-cleanup-all-worktrees`
   - 全プロジェクトの孤立worktreeを検出
   - 未コミット変更がある場合は警告
   - force削除するか確認

**実装ファイル**:
- `.emacs.d/elisp/claude-code-projects.el:61-80` (自動)
- `.emacs.d/elisp/claude-code-projects.el:458-515` (手動)
- `.emacs.d/init.el:481-483` (自動起動設定)

### 5. フォールバック処理

**問題**: AUTO-GENERATEDマーカーがない場合、cage設定に追加できない

**解決策**: 3段階のフォールバック
1. マーカーを探す → 見つかれば後に追加
2. 見つからない → ファイル末尾にマーカーとworktreeパスを追加
3. インデントは既存の`allow:`エントリに合わせる

**実装ファイル**:
- `.emacs.d/elisp/claude-code-projects.el:82-123`
- 自動的にマーカーを挿入し、エラーを回避

## 新しいコマンド

### Worktree管理
```elisp
M-x claude-code-list-worktrees       # プロジェクトのworktree一覧
M-x claude-code-open-worktree        # 既存worktreeでセッション開く
M-x claude-code-cleanup-all-worktrees # 孤立worktreeを削除
M-x claude-code-kill-session         # 現在のセッション終了（worktree削除可能）
```

### セッション管理（更新）
```elisp
M-x claude-code-switch-session       # セッション切り替え
M-x claude-code-list-sessions        # アクティブセッション一覧
M-x claude-code-kill-all-sessions    # 全セッション終了（worktree削除可能）
```

## データ構造の変更

### セッション情報
**変更前**:
```elisp
(PROJECT-NAME . BUFFER-NAME)
```

**変更後**:
```elisp
(PROJECT-NAME BUFFER-NAME WORKTREE-PATH)
;; WORKTREE-PATHはworktree未使用の場合nil
```

## 設定ファイルの変更

### init.el
```elisp
;; 追加されたコマンド
:commands (
  ...
  claude-code-cleanup-all-worktrees  ;; 新規
  ...
)

;; 起動時自動クリーンアップ
(run-with-idle-timer 5 nil #'claude-code-projects--cleanup-orphaned-worktrees)
```

### cage設定の自動管理
```yaml
# ~/.config/cage/presets.yaml
presets:
  claude-code:
    allow:
      - "."
      - "/Users/pongchang/dotfiles"
      # AUTO-GENERATED: Do not edit below this line
      - "/Users/pongchang/dotfiles-feature-a"  # worktree (auto-added)
      - "/Users/pongchang/dotfiles-bugfix-123" # worktree (auto-added)
```

## 使用方法

### 基本ワークフロー

**1. 新機能開発で別worktreeを使用**:
```elisp
C-c C-p → dotfiles → Create new session
→ "Create git worktree? y"
→ Branch name: feature-new-ui
→ 自動的に ~/dotfiles-feature-new-ui が作成される
→ cage設定に追加される
→ セッション起動
```

**2. メインブランチで別作業**:
```elisp
C-c C-p → dotfiles → Create new session
→ "Create git worktree? n"
→ メインディレクトリ ~/dotfiles でセッション起動
```

**3. 作業完了後の削除**:
```elisp
;; worktreeセッション内で
M-x claude-code-kill-session
→ "Kill session? y"
→ "Remove worktree? y"
→ 未コミット変更があれば警告
→ worktreeディレクトリ削除
→ cage設定から削除
```

### クラッシュからの復旧

**PCクラッシュ後**:
```
1. Emacs再起動
   ↓
2. 5秒後に自動クリーンアップ実行
   → cage設定から孤立エントリを削除
   → worktreeディレクトリは残る（未コミット変更保護）
   ↓
3. 必要に応じて手動クリーンアップ
   M-x claude-code-cleanup-all-worktrees
   → 孤立worktreeの一覧表示
   → 未コミット変更があれば警告
   → force削除するか確認
```

## テストシナリオ

### 1. 基本動作テスト
```elisp
;; Emacs内で実行
C-c C-p → dotfiles → Create new session
→ "Create git worktree? y"
→ Branch name: test-feature

;; 確認
ls ~/dotfiles-test-feature  # ディレクトリ存在
cat ~/.config/cage/presets.yaml | grep test-feature  # cage設定追加
```

### 2. 未コミット変更保護テスト
```bash
cd ~/dotfiles-test-feature
echo "test" > test.txt
git status  # 未コミット変更あり
```

```elisp
;; Emacsで削除試行
M-x claude-code-kill-session
→ "⚠️ WARNING: Has uncommitted changes!"
→ n を選択
→ worktreeが保持される ✅
```

### 3. クリーンアップテスト
```elisp
;; Emacsを強制終了（C-x C-c せずにkill）
;; Emacs再起動
;; 5秒待つ
→ "Cleaned up 1 orphaned worktree(s) from cage config"

;; 確認
cat ~/.config/cage/presets.yaml | grep test-feature  # エントリ削除
ls ~/dotfiles-test-feature  # ディレクトリは残る
```

## 変更を有効にする方法

### オプション1: Emacs再起動（推奨）
```elisp
C-x C-c  ;; Emacs終了
;; Emacs再起動
→ すべての変更が反映される ✅
```

### オプション2: 手動リロード
```elisp
;; 1. パッケージリロード
M-x load-file RET
~/.emacs.d/elisp/claude-code-projects.el RET

;; 2. init.el再評価（init.elを開いた状態で）
M-x eval-buffer RET
```

## トラブルシューティング

### Q: Worktree作成時に "Operation not permitted" エラー
**A**: cage設定への追加が失敗している可能性があります
```elisp
;; 確認
cat ~/.config/cage/presets.yaml

;; AUTO-GENERATEDマーカーが存在するか確認
;; なければフォールバック処理が動作しているはず

;; 手動で確認
M-x claude-code-cleanup-all-worktrees
```

### Q: cage設定に worktreeパスが追加されない
**A**: AUTO-GENERATEDマーカーと`allow:`セクションを確認
```yaml
# 必要な構造
presets:
  claude-code:
    allow:  # ← このセクションが必要
      - "."
      # AUTO-GENERATED: Do not edit below this line  # ← このマーカーが推奨
```

### Q: 未コミット変更があるのに削除できてしまう
**A**: force削除を承認している可能性があります
```
"Remove worktree? y"
→ "⚠️ WARNING: Has uncommitted changes!"
→ "Force remove? y"  # ← ここでyを選択すると削除される
```

## セキュリティ

### Cage Sandboxの維持
- ✅ Worktree作成時に自動的にcage設定に追加
- ✅ Worktreeディレクトリでもcageサンドボックスが有効
- ✅ セッション終了時にcage設定から削除（クリーンアップ）

### 未コミット変更の保護
- ✅ 削除前に`git status`でチェック
- ✅ 変更がある場合は警告表示
- ✅ force削除には明示的な確認が必要
- ✅ 自動クリーンアップはcage設定のみ削除（ディレクトリは保持）

## ベストプラクティス

### ✅ 推奨される使い方
- 複数機能を同時開発: 各機能でworktreeを作成
- PRレビュー中に別作業: mainで作業しながら、別ブランチをworktreeで確認
- 長期実験ブランチ: worktreeで実験的変更を維持

### ⚠️ 注意点
- 調査のみなら不要: 読み取り専用ならworktreeなしでもOK
- 作業完了後は削除: 不要なworktreeは削除してクリーンに保つ
- 未コミット変更は定期的にコミット: クラッシュ対策

## 関連ファイル

### 実装コード
- `.emacs.d/elisp/claude-code-projects.el` - メイン実装
- `.emacs.d/init.el` - 設定とコマンド登録

### 設定ファイル
- `.config/cage/presets.yaml` - Cage設定（自動管理）
- `.config/cage/presets.yaml.template` - テンプレート

### ドキュメント
- `CLAUDE.md` - ユーザー向けドキュメント
- `.claude/docs/WORKTREE-INTEGRATION.md` - この詳細ドキュメント

## 変更履歴

### 2026-04-13: 初回実装
- Git worktree統合
- Cage設定の動的管理
- 未コミット変更の保護
- クラッシュ対策（自動クリーンアップ）
- フォールバック処理（AUTO-GENERATEDマーカー）

## 今後の拡張案

1. ブランチ削除オプション: worktree削除時にブランチも削除するか選択
2. カスタムディレクトリ名: ブランチ名から自動生成ではなく、手動指定
3. Worktree一覧のUIフィルタリング: プロジェクトごとに絞り込み
4. Cage設定のバリデーション: 設定ファイルの構造チェック

---

**End of Document**
