# 次のセッション開始時の指示書

## 状況サマリー

**問題**: `.emacs.d/elisp/claude-code-projects.el`の`claude-code-select-project`関数が動作しない

**症状**:
- `C-c C-p`でプロジェクト選択時、ミニバッファに"nil"が表示される
- Claude Codeセッションが起動しない可能性あり

**これまでの修正**:
- ✅ シンタックスエラー（括弧バランス）: 解決
- ✅ `buffer-name`スコープエラー: 解決
- ✅ コンパイルエラー: 解決
- ⚠️ 動作の問題: 未解決

## 次のセッションで最初にすること

### 1. 必要なファイルを共有

以下の3ファイルを最初に見せてください：

```
1. .serena/memories/troubleshooting/claude-code-projects-el-fix-2026-03-23.md
2. .emacs.d/elisp/claude-code-projects.el
3. .emacs.d/custom.el
```

### 2. 現在の状態を確認

Emacsで以下を順番に実行して、結果を全て教えてください：

```elisp
;; A. プロジェクトリストが読み込まれているか
M-x eval-expression RET claude-code-projects-list RET
;; → 結果:

;; B. デバッグモードを有効化
M-x toggle-debug-on-error RET

;; C. プロジェクトを選択
C-c C-p
;; → どのプロジェクトを選びますか？
;; → 選択後に何が起こりますか？
;; → エラーが出ますか？スタックトレースは？

;; D. Messagesバッファを確認
C-h e
;; → 最後の10行の内容を教えてください

;; E. バッファリストを確認
C-x C-b
;; → *claude:* で始まるバッファはありますか？
```

### 3. claude-code-runの動作確認

手動でclaude-code-runを実行してみてください：

```elisp
M-x eval-expression RET
(let ((default-directory "~/dotfiles/"))
  (claude-code-run))
RET
```

**確認事項**:
- バッファは起動しますか？
- 何が返ってきますか？
- エラーは出ますか？

### 4. 動作するプロジェクトと比較

```elisp
;; dotfilesプロジェクトで試す
C-c C-p → dotfiles を選択
;; → 起動しますか？

;; ponプロジェクトで試す
C-c C-p → pon を選択
;; → 起動しますか？

;; AFK-Callerプロジェクトで試す（これが問題）
C-c C-p → AFK-Caller を選択
;; → "nil"が表示される
```

**比較ポイント**:
- 動くプロジェクトと動かないプロジェクトの違いは？
- ディレクトリの中身の有無は関係ありますか？

## デバッグのポイント

### 可能性A: claude-code-runが失敗している

**確認方法**:
```elisp
;; claude-code-runの定義を確認
M-x describe-function RET claude-code-run RET

;; 手動実行
M-x claude-code-run RET
;; → 空ディレクトリで実行できるか？
```

### 可能性B: vtermが問題

**確認方法**:
```elisp
;; vtermが正常に動くか
M-x vterm RET
;; → 起動しますか？
```

### 可能性C: cage設定の問題

**確認方法**:
```bash
# iTerm2で実行
cd ~/AFK-Caller
cage -config "$HOME/.config/cage/presets.yaml" -preset claude-code claude --version
# → 起動しますか？
```

## 修正の方針

### パターン1: claude-code-runが原因なら

関数を修正して、エラーハンドリングを追加：

```elisp
(condition-case err
    (claude-code-run)
  (error
   (message "Failed to start Claude Code: %s" err)))
```

### パターン2: 空ディレクトリが原因なら

ディレクトリチェックを強化：

```elisp
(when (and (file-directory-p expanded-dir)
           (> (length (directory-files expanded-dir)) 2))  ; . と .. 以外にファイルがある
  ...)
```

### パターン3: 戻り値の問題なら

関数全体を`progn`でラップ：

```elisp
(progn
  (claude-code-run)
  ...
  (message "Started...")
  t)  ; 明示的にtを返す
```

## エスカレーション判断

以下のどれかに該当したら、別のアプローチを検討：

1. ✅ デバッグ情報でスタックトレースが得られた
   → エラー箇所を修正

2. ✅ claude-code-runが失敗している
   → claude-codeパッケージの問題を調査

3. ✅ 空ディレクトリが原因
   → ディレクトリチェックを追加

4. ❌ 上記全て試してもダメ
   → 関数を最小限に簡略化してゼロから書き直し

## 成功条件

以下が全て達成できたら完了：

- [ ] `C-c C-p`でプロジェクト選択できる
- [ ] 選択後、Claude Codeセッションが起動する
- [ ] ミニバッファに正常なメッセージが表示される
- [ ] 空ディレクトリでも適切にエラーまたは警告が出る

## 参考情報

### 関連メモリー
- `troubleshooting/cage-eperm-2026-03-22.md` - cage symlink問題（解決済み）
- `troubleshooting/claude-code-projects-el-fix-2026-03-23.md` - このセッションの詳細

### 動作確認済みの環境
- macOS 14.7.6 (Sonoma)
- Emacs (GUI版 `/Applications/Emacs.app`)
- claude-code パッケージ（ELPA経由）
- cage 0.1.13

### 重要な設定
- `claude-code-projects-use-cage`: `t` (有効)
- `claude-code-projects-cage-config`: `~/.config/cage/presets.yaml`
- `~/.claude` → `~/dotfiles/.claude` (symlink with eval-symlinks)

---

**最終更新**: 2026-03-23 21:30 JST
**優先度**: 高
**推定所要時間**: 30-60分
