# Emacs 30+ 対応アップグレードノート

## 主な変更点

### 1. パッケージ管理の改善

#### el-getの削除
- **変更前**: `el-get`を使用してパッケージをインストール
- **変更後**: すべてのパッケージをMELPAから直接インストール
- **理由**: `el-get`は保守が活発でなく、MELPAで十分に対応可能

特に`web-php-blade-mode`は`web-mode`に統合されました:
```elisp
;; 変更前
(el-get-bundle 'web-php-blade-mode
  :url "https://github.com/takeokunn/web-php-blade-mode.git")

;; 変更後
(leaf web-mode
  :mode ("\\.blade\\.php\\'" . web-mode)
  :custom
  ((web-mode-engines-alist . '(("blade" . "\\.blade\\.php\\'")))))
```

### 2. パフォーマンス最適化

#### GC（ガベージコレクション）の最適化
```elisp
;; 起動時はGCを抑制
(setq gc-cons-threshold most-positive-fixnum
      gc-cons-percentage 0.6)

;; 起動後に適切な値に戻す
(add-hook 'emacs-startup-hook
          (lambda ()
            (setq gc-cons-threshold (* 16 1024 1024)
                  gc-cons-percentage 0.1)))
```

#### ファイル名ハンドラーの最適化
起動時にファイル名ハンドラーを一時的に無効化し、起動後に復元することで起動時間を短縮。

#### 遅延ロード（`:defer t`）の活用
以下のパッケージに遅延ロードを適用:
- `lsp-mode`
- `company`
- `projectile`
- `magit`
- `rust-mode`
- `org-roam`
- `org-journal`
- `helm`

### 3. LSP設定の改善

#### lsp-mode
```elisp
;; 変更前
(lsp-document-sync-method . 2)

;; 変更後
(lsp-document-sync-method . 'incremental)
```

パフォーマンス向上のため無効化:
- `lsp-lens-enable`
- `lsp-ui-sideline-enable`
- `lsp-modeline-code-actions-enable`
- `lsp-modeline-diagnostics-enable`

### 4. org-roamの最新化

```elisp
;; 変更前
(org-roam-database-connector . 'sqlite)

;; 変更後
(org-roam-v2-ack . t)  ;; database-connectorは自動検出されるため不要
(org-roam-db-autosync-mode)  ;; 自動同期モードを有効化
```

### 5. exec-path-from-shellの改善

```elisp
;; パフォーマンス向上のための新設定
(exec-path-from-shell-check-startup-files . nil)
(exec-path-from-shell-warn-duration-millis . 1000)
```

### 6. その他のパッケージ最適化

#### company
```elisp
(company-idle-delay . 0.1)
(company-tooltip-align-annotations . t)
(company-transformers . '(company-sort-by-occurrence))
```

#### projectile
```elisp
(projectile-enable-caching . t)
(projectile-git-use-fd . t)
(projectile-use-git-grep . t)
```

#### helm
```elisp
(helm-mode-fuzzy-match . t)
(helm-completion-in-region-fuzzy-match . t)
(helm-candidate-number-limit . 100)
```

## 互換性チェック

起動時に以下の情報をレポート:
- Emacsバージョン
- SQLiteサポート状況
- ネイティブコンパイル状況
- インストール済みパッケージ数
- 起動時間

## 推奨事項

### パッケージの再インストール
アップグレード後、一度パッケージを再インストールすることを推奨:
```elisp
M-x package-refresh-contents
M-x package-install-selected-packages
```

### 古いel-getディレクトリの削除
```bash
rm -rf ~/.emacs.d/el-get
```

### org-roamデータベースの再構築（必要に応じて）
```elisp
M-x org-roam-db-sync
```

## トラブルシューティング

### SQLiteエラー
Emacs 29以降でorg-roamを使用する場合、SQLiteサポートが必要です。エラーが出る場合:
```bash
# macOSの場合
brew install emacs-plus --with-native-comp --with-sqlite3

# または
brew install emacs --with-native-comp
```

### LSPが動作しない
言語サーバーが正しくインストールされているか確認:
```bash
# Rust
rustup component add rust-analyzer

# TypeScript/JavaScript
npm install -g typescript-language-server typescript
```

### 起動が遅い
`~/.emacs.d/elpa/`内の古いパッケージを削除:
```bash
rm -rf ~/.emacs.d/elpa/*
```
その後、Emacsを起動してパッケージを再インストール。

## 今後のメンテナンス

- 定期的に`M-x package-list-packages`でパッケージを更新
- 非推奨の警告が出たら、該当する設定を最新版に更新
- Emacs 31以降でさらに最適化が可能な場合は追加検討
