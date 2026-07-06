# Emacs Elisp Reload - Troubleshooting Guide

## Problem Pattern

**Symptom**: 
- `.el`ファイルを編集しても変更が反映されない
- Emacsを再起動しても古い動作のまま
- エラーが出ない（構文は正しい）のに期待通りに動作しない

**Root Cause**:
1. **古い`.elc`ファイル**（バイトコンパイル済み）が優先的にロードされる
2. **メモリに残った古い関数定義**が使われ続ける
3. **遅延ロード設定**（`:load-path`, `:defer`, `:commands`など）により、再起動してもリロードされない

## Solution Strategy

### Step 1: 古いバイトコードを削除

```bash
# 全ての.elcを削除
find ~/.emacs.d -name "*.elc" -delete

# または特定ファイルのみ
rm ~/.emacs.d/elisp/target-file.elc
```

### Step 2: Emacsで明示的にリロード

```elisp
M-x load-file RET ~/.emacs.d/elisp/target-file.el RET
```

または`*scratch*`で：
```elisp
(load-file "~/.emacs.d/elisp/target-file.el")
```

### Step 3: 関数定義を確認

```elisp
M-x describe-function RET function-name RET
```

ファイルパスを確認し、正しい`.el`から読み込まれているか確認

## Debugging Workflow

### 1. バッチモードで構文チェック

```bash
/Applications/Emacs.app/Contents/MacOS/Emacs --batch \
  --eval "(load-file \"~/.emacs.d/elisp/target-file.el\")" \
  2>&1 | grep -E "(Error|Warning)"
```

### 2. 関数が定義されているか確認

```bash
/Applications/Emacs.app/Contents/MacOS/Emacs --batch \
  --eval "(progn
    (load-file \"~/.emacs.d/init.el\")
    (require 'target-package)
    (if (fboundp 'target-function)
        (message \"✅ Defined\")
      (message \"❌ NOT defined\"))
  )"
```

### 3. 手動で段階的にテスト

`*scratch*`バッファで関数を簡略化して実行：

```elisp
(defun test-simple-version ()
  (interactive)
  (message "Step 1")
  ;; 最小限のコードで動作確認
  (message "Step 2")
  ;; 徐々に本来の処理を追加
  )

M-x test-simple-version
```

動く最小バージョンから、少しずつ本来の処理を追加して問題箇所を特定

### 4. デバッグモードで実行

```elisp
M-: (setq debug-on-error t) RET
M-x target-function
```

エラーが出ればスタックトレースで原因特定

## Common Mistakes

### ❌ Emacs再起動だけでは不十分

```elisp
;; init.elで遅延ロード設定
(use-package my-package
  :load-path "elisp"
  :commands (my-function))  ; C-c C-pなど押すまでロードされない
```

→ 再起動しても、キーバインド押下まで古い定義が残る

### ❌ .elcが残っている

```bash
# .elファイルを編集
vim ~/.emacs.d/elisp/my-package.el

# Emacs再起動
# → .elcが優先され、編集が反映されない！
```

### ❌ 構文エラーを見逃す

```bash
# バッチモードでチェックせずGUIで試す
# → エラーが静かに無視される場合がある
```

## Best Practices

### 開発時は.elcを使わない

```elisp
;; init.el または開発中のパッケージ
;; byte-compileしない（生の.elファイルを使う）
```

### ファイル編集後は必ずリロード

```elisp
;; 1. ファイル保存
C-x C-s

;; 2. 即座にリロード
M-x load-file RET

;; 3. 関数実行
M-x my-function
```

### use-packageの:load-pathに注意

```elisp
(use-package my-package
  :load-path "elisp"  ; 遅延ロードされる
  :commands (my-function))

;; 開発中は:requireを追加して即座にロード
(use-package my-package
  :load-path "elisp"
  :require t  ; 起動時に必ずロード
  :commands (my-function))
```

## Case Study: claude-code-projects.el

**問題**:
- `init.el`から`cleanup-orphaned-worktrees`タイマーを削除
- Emacs再起動してもエラーが消えない
- `C-c C-p`でプロジェクト選択しても何も起こらない

**原因**:
1. `.elc`ファイルに古いコードが残っていた
2. `:load-path "elisp"`で遅延ロードされていた
3. メモリに古い関数定義が残っていた

**解決**:
```bash
# 1. .elcを削除
rm ~/.emacs.d/elisp/claude-code-projects.elc

# 2. 元のファイルに戻す（デバッグメッセージで構文エラーが発生したため）
git checkout .emacs.d/elisp/claude-code-projects.el

# 3. Emacsで明示的にリロード
M-x load-file RET ~/.emacs.d/elisp/claude-code-projects.el RET

# 4. 動作確認
C-c C-p → dotfiles → ✅ 起動成功
```

## Quick Reference

| 症状 | 原因 | 解決策 |
|------|------|--------|
| 編集が反映されない | `.elc`が古い | `find ~/.emacs.d -name "*.elc" -delete` |
| 再起動しても変わらない | 遅延ロード | `M-x load-file` |
| エラーが出ない | 構文エラーが無視される | バッチモードでチェック |
| 関数が未定義 | requireされていない | `(require 'package-name)` |
| 動く時と動かない時がある | タイミング問題 | `:require t`で即座にロード |

## Verification Checklist

- [ ] `.elc`ファイルを削除した
- [ ] バッチモードで構文エラーなし
- [ ] `M-x load-file`でリロードした
- [ ] `M-x describe-function`でファイルパス確認
- [ ] 関数が正しく定義されている（`fboundp`で確認）
- [ ] 期待通りの動作をする

## Related Skills

- `emacs-verification/SKILL.md` - Emacs設定の検証方法
- `troubleshooting/claude-code-projects-el-fix-2026-03-23.md` - 過去のトラブル記録
