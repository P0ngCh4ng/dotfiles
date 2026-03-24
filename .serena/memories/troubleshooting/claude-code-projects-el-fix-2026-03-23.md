# claude-code-projects.el修正作業 - 進行中 (2026-03-23)

## 問題の経緯

### 発端
cage symlink問題解決後、`.emacs.d/elisp/claude-code-projects.el`に複数の問題が発生。

### 発生した問題

1. **"end of file during parsing"エラー**
   - 原因: 括弧の対応ミス
   - 状態: ✅ 解決済み

2. **`buffer-name`スコープエラー**
   - 原因: `let`のネスト構造でスコープが正しくない
   - 修正: `session-buffer-name`に変数名変更
   - 状態: ✅ 解決済み

3. **`claude-code-projects-list`が`nil`**
   - 原因: `custom.el`が読み込まれていない可能性
   - 対処: Emacsの再起動またはcustom.elの手動ロードが必要
   - 状態: ⚠️ 部分的に解決

4. **ミニバッファに"nil"が表示される**
   - 原因: 関数の戻り値が明示的でない
   - 修正: `message`関数で戻り値を設定
   - 状態: ⚠️ 未確認（ユーザー報告では未解決）

## 現在のコード状態

### ファイル: `.emacs.d/elisp/claude-code-projects.el`

**修正された箇所（105-144行目）**:

```elisp
;;;###autoload
(defun claude-code-select-project ()
  "Select a project from predefined list and start Claude Code."
  (interactive)
  (let* ((project (completing-read "Select project: " claude-code-projects-list nil t))
         (dir (cdr (assoc project claude-code-projects-list))))
    (cond
     ;; Check if project directory is configured
     ((not dir)
      (user-error "Project directory not configured for: %s" project))
     ;; Check if directory string is empty
     ((string-empty-p dir)
      (user-error "Project directory is empty for: %s" project))
     ;; Directory is configured, proceed
     (t
      (let* ((expanded-dir (expand-file-name dir))
             (project-dir expanded-dir))
        ;; Check if directory exists
        (unless (file-directory-p expanded-dir)
          (user-error "Directory does not exist: %s" expanded-dir))
        ;; Set default-directory and claude-code-executable
        (let ((default-directory expanded-dir)
              (claude-code-executable (claude-code-projects--get-command)))
          (claude-code-run)
          ;; Track session and get buffer name
          (let ((session-buffer-name (buffer-name)))
            (add-to-list 'claude-code-projects-sessions
                         (cons project session-buffer-name))
            ;; cage使用時はworking directoryが正しく設定されないため、
            ;; vterm起動後に明示的にcdコマンドを送信
            (when claude-code-projects-use-cage
              (run-with-timer 1.5 nil
                             (lambda (dir buf-name)
                               (when-let ((buf (get-buffer buf-name)))
                                 (with-current-buffer buf
                                   (require 'vterm)
                                   (vterm-send-string (format "cd \"%s\"" dir))
                                   (vterm-send-return))))
                             project-dir session-buffer-name))
            ;; Return meaningful message
            (message "Started Claude Code session for project: %s" project))))))))
```

**変更点**:
1. ✅ `cond`で条件分岐を明確化
2. ✅ ディレクトリチェックを追加（nil、空文字列、存在確認）
3. ✅ `let*`でネスト構造を整理
4. ✅ `session-buffer-name`で変数名を明確化
5. ✅ `message`で戻り値を設定

## 検証済み事項

### コンパイルチェック
```bash
cd ~/dotfiles
/Applications/Emacs.app/Contents/MacOS/Emacs --batch \
  --eval "(byte-compile-file \".emacs.d/elisp/claude-code-projects.el\")"
```

**結果**: エラーなし（Warningのみ）

### 括弧バランス
```bash
# 105-144行目
開き括弧: 52個
閉じ括弧: 52個
```

**結果**: ✅ バランス正常

### プロジェクトリスト（custom.el）
```elisp
'(claude-code-projects-list
   '(("AFK-Caller" . "~/AFK-Caller/") ("guiano" . "~/guiano/")
     ("dotfiles" . "~/dotfiles") ("pon" . "~/pon")
     ("sokko" . "~/sokko") ("chatclinic" . "~/chatclinic")
     ("AutomationVideo" . "~/AutomationVideo")
     ("mcpCreate" . "~/mcpCreate")))
```

**状態**: 設定は正しい

## 未解決の問題

### 1. ミニバッファに"nil"が表示される

**症状**:
- `C-c C-p`でプロジェクト選択
- AFK-Callerを選択
- ミニバッファに"nil"が表示

**確認済み**:
- ディレクトリは存在する（`~/AFK-Caller/`）
- ディレクトリは空
- プロジェクトリストの設定は正しい: `(("AFK-Caller" . "~/AFK-Caller/") "~/AFK-Caller/")`

**未確認**:
- Claude Codeバッファは実際に起動しているか？
- `*Messages*`バッファに何が表示されているか？
- エラーログの詳細

### 2. 根本原因の可能性

**仮説A**: `claude-code-run`が失敗している
- 空ディレクトリでClaude Codeが起動できない
- `claude-code-run`自体がnilを返している

**仮説B**: `message`の戻り値が表示されていない
- 何らかの理由でmessageが実行されていない
- または別のエラーで途中で止まっている

**仮説C**: vtermまたはclaude-codeパッケージの問題
- 依存パッケージの不具合
- バージョン互換性の問題

## 次のセッションで実施すべきこと

### 1. 詳細なデバッグ情報の取得

```elisp
;; Emacsで実行
M-x toggle-debug-on-error RET
C-c C-p
;; → AFK-Callerを選択
;; → スタックトレースを確認
```

### 2. claude-code-runの戻り値確認

```elisp
M-x eval-expression RET
(let ((default-directory "~/AFK-Caller/")
      (claude-code-executable (claude-code-projects--get-command)))
  (claude-code-run))
RET
;; → 何が返ってくる？
;; → バッファは起動する？
```

### 3. *Messages*バッファの確認

```elisp
C-h e
;; または
M-x view-echo-area-messages RET
;; → エラーメッセージを全て確認
```

### 4. 代替アプローチ: 動作するプロジェクトと比較

```elisp
;; dotfilesで試す（これは動くはず）
C-c C-p → dotfiles を選択
;; → 正常に起動するか？

;; ponで試す
C-c C-p → pon を選択
;; → 正常に起動するか？
```

### 5. 最後の手段: 関数の簡略化

もし上記全てでダメなら、関数を最小限に簡略化してテスト：

```elisp
(defun claude-code-select-project-minimal ()
  (interactive)
  (let* ((project (completing-read "Select project: " claude-code-projects-list nil t))
         (dir (cdr (assoc project claude-code-projects-list))))
    (when dir
      (let ((default-directory (expand-file-name dir)))
        (call-interactively 'claude-code-run)))))
```

## 関連ファイル

1. **設定ファイル**:
   - `~/.emacs.d/elisp/claude-code-projects.el` (修正中)
   - `~/.emacs.d/custom.el` (プロジェクトリスト定義)
   - `~/.emacs.d/init.el` (ロード設定)

2. **ログファイル**:
   - `~/.serena/memories/troubleshooting/cage-eperm-2026-03-22.md` (cage問題解決)
   - `~/.serena/memories/troubleshooting/claude-code-projects-el-fix-2026-03-23.md` (このファイル)

3. **依存パッケージ**:
   - `claude-code` (公式パッケージ)
   - `vterm` (必須依存)

## 最終ステータス

- ✅ シンタックスエラー: 解決
- ✅ 括弧バランス: 正常
- ✅ コンパイル: 成功
- ⚠️ 動作: まだ未解決（ミニバッファに"nil"表示）

**次のセッション開始時に共有すべきファイル**:
1. このメモリー: `.serena/memories/troubleshooting/claude-code-projects-el-fix-2026-03-23.md`
2. 問題のファイル: `.emacs.d/elisp/claude-code-projects.el`
3. 設定ファイル: `.emacs.d/custom.el`

**優先度**:
- 高: デバッグ情報の取得（toggle-debug-on-error）
- 高: claude-code-runの戻り値確認
- 中: 動作するプロジェクトとの比較
- 低: 関数の簡略化

---

**作成日時**: 2026-03-23 21:30 JST
**ステータス**: 作業継続中
