# Dotfiles

Personal dotfiles and development environment configuration for macOS/Linux.

## 概要

このリポジトリは個人用のdotfilesと開発環境設定を管理します。シンボリックリンクによる自動配置と、プラットフォーム別の初期化スクリプトにより、新しい環境を素早くセットアップできます。

## 主な機能

### 🎯 統合プロジェクト管理
- **projects.yml**: PC上の全プロジェクトを一元管理
- **ポート管理**: ポート競合を自動検出
- **データベース管理**: 接続、バックアップ、復元を統合コマンドで実行
- **Cage統合**: 自動生成されたサンドボックス設定で安全な環境を提供

詳細は [PROJECT_MANAGEMENT.md](./PROJECT_MANAGEMENT.md) を参照

### ⚙️ Shell Configuration
- **Zsh**: カスタム関数、エイリアス、プロンプト設定
- **自動補完**: Homebrew統合、Git補完
- **履歴管理**: 重複排除、ディレクトリ移動時の自動 `ls`

主要ファイル:
- `.zshrc` - メインシェル設定
- `db.zsh` - データベース管理関数
- `opt.zsh` - Zshオプション設定

### 📝 Emacs Configuration
- **Claude Code統合**: Emacs内でClaude Codeを完全に利用
- **Cage サンドボックス**: シンボリックリンク解決機能付き
- **モジュラー構成**: `elisp/`, `conf/`, `themes/` で整理

詳細は [CLAUDE.md § Emacs](./CLAUDE.md#emacs-configuration) を参照

### 🔧 自動化スクリプト
- `bin/update-cage-config` - projects.ymlからcage設定を自動生成
- `bin/fix-project-quarantine` - macOSの隔離属性を削除
- `bin/emacs-auto-fix` - Emacs設定の自動検証と修正

## クイックスタート

### インストール

```bash
# リポジトリをクローン
git clone https://github.com/yourusername/dotfiles.git ~/dotfiles
cd ~/dotfiles

# 完全セットアップ（リポジトリ更新 + シンボリックリンク配置 + 初期化）
make install
```

### 主要コマンド

```bash
# Dotfiles管理
make deploy        # シンボリックリンクを作成
make update        # リポジトリを更新
make update-cage   # cage設定を再生成
make clean         # 全シンボリックリンクを削除

# プロジェクト管理
pj-info <project>       # プロジェクト情報を表示
check-ports             # ポート割り当てを確認
port-scan               # 使用中のポートをスキャン

# データベース管理
db-list <project>               # データベース一覧
db-connect <project> <db-name>  # データベース接続
db-backup <project> <db-name>   # バックアップ作成
db-restore <project> <db-name>  # バックアップから復元
db-status <project>             # コンテナ状態確認
```

詳細は `make help` で確認

## ファイル構成

```
~/dotfiles/
├── .zshrc                    # メインシェル設定
├── .zshenv                   # 環境変数
├── db.zsh                    # データベース管理関数
├── opt.zsh                   # Zshオプション
├── .emacs.d/                 # Emacs設定ディレクトリ
│   ├── init.el              # メイン設定ファイル
│   ├── elisp/               # カスタムElispパッケージ
│   └── conf/                # 設定ファイル
├── bin/                      # 自動化スクリプト
│   ├── update-cage-config   # Cage設定自動生成
│   └── fix-project-quarantine
├── etc/init/                 # プラットフォーム別初期化
│   ├── osx/                 # macOS用スクリプト
│   └── linux/               # Linux用スクリプト
├── .config/cage/             # Cage設定
│   ├── presets.yaml         # 自動生成（編集禁止）
│   └── presets.yaml.template
├── projects.yml              # プロジェクト設定（gitignored）
├── projects.yml.example      # テンプレート
├── Brewfile                  # Homebrew依存関係
├── Makefile                  # 主要管理インターフェース
├── README.md                 # このファイル
├── CLAUDE.md                 # Claude Code用プロジェクト情報
└── PROJECT_MANAGEMENT.md     # プロジェクト管理ガイド
```

## プロジェクト管理システム

このdotfilesは**全プロジェクトの中央レジストリ**として機能します。

### セットアップ手順

1. **projects.ymlを作成**
   ```bash
   cp projects.yml.example projects.yml
   ```

2. **プロジェクトを追加**
   ```yaml
   projects:
     myproject:
       path: ~/projects/myapp
       ports: [3000, 3001]
       description: "My awesome app"
       tech: [node, react, postgresql]
       databases:
         - name: main
           type: postgresql
           host: localhost
           database: myapp_dev
           user: postgres
   ```

3. **Cage設定を更新**
   ```bash
   make update-cage  # または make deploy
   ```

4. **データベースパスワードを設定**
   ```bash
   db-set-password myproject main
   ```

詳細は [PROJECT_MANAGEMENT.md](./PROJECT_MANAGEMENT.md) を参照

## 環境

### サポートプラットフォーム
- **macOS** (主要環境)
- **Linux**
- **Cygwin** (限定的サポート)

### 必要なツール
- Zsh
- Git
- Homebrew (macOS)
- Emacs 29+

Brewfileで定義されたパッケージは `make install` で自動インストールされます。

## グローバルルールシステム

**最終更新**: 2026-03-27

Claude Code用のグローバルルールは階層構造で管理されています:

```
~/.claude/rules/
├── common/                   # 全プロジェクト共通（最優先）
│   ├── 00-session-start.md  # セッション開始時の必須プロトコル
│   ├── agent-automation.md
│   ├── project-management.md
│   └── ...
└── dotfiles/                 # Dotfiles専用ルール
    ├── emacs-environment.md
    ├── database-management.md
    └── verification-strategy.md
```

### 強制メカニズム

1. **SessionStart Hook** - 毎セッション開始時にprojects.ymlから自動的にプロジェクト情報を読み込み
2. **PostToolUse Hook** - Edit/Write後にcode-reviewerエージェントの起動を促す

詳細は [CLAUDE.md § Global Rules System](./CLAUDE.md#-critical-global-rules-system) を参照

## Emacsでの開発

このdotfilesでは**Emacs内でClaude Codeを利用**します（ターミナルではない）。

### パッケージ構成
- **公式パッケージ**: `claude-code` (ELPA)
- **カスタム拡張**: `claude-code-projects` (プロジェクトショートカット)

### キーバインド
```
C-c c    - Claude Code Transientメニュー
C-c C-p  - プロジェクト選択
C-c C-w  - セッション切り替え
C-c C-l  - セッション一覧
```

### ワークフロー例
1. `C-c C-p` → "dotfiles"を選択
2. `C-c c` → Transientメニューを開く
3. `p` → プロンプトバッファを開く
4. リクエストを入力（`@`でファイル補完）
5. `C-c C-b` → Claude Codeに送信

詳細は [CLAUDE.md § Claude Code in Emacs](./CLAUDE.md#claude-code-in-emacs) を参照

## トラブルシューティング

### EPERM Error (Cage + Symlinks)
`.claude`がシンボリックリンクの場合、cage設定に `eval-symlinks: true` が必要です:

```yaml
presets:
  claude-code:
    allow:
      - path: "/Users/pongchang/.claude"
        eval-symlinks: true
```

解決後、`make update-cage` で設定を再生成してください。

### ポート競合
```bash
check-ports      # 競合を確認
port-scan        # 使用中のポートを特定
# projects.ymlでポート番号を変更
```

### データベース接続エラー
```bash
db-status myproject          # コンテナ状態を確認
db-start myproject           # コンテナを起動
db-test-connection myproject main  # 接続テスト
```

## ドキュメント

- **README.md** (このファイル) - リポジトリの概要
- **CLAUDE.md** - Claude Code用プロジェクト情報
- **PROJECT_MANAGEMENT.md** - プロジェクト管理システムの詳細ガイド
- **~/.claude/rules/** - Claude Code用グローバルルール
- **~/.claude/skills/** - 実装パターンとスキル

## 今後の予定

- [ ] Git ブランチトラッキング
- [ ] 依存関係管理
- [ ] MongoDB/Redis フルサポート
- [ ] バッチ操作（複数プロジェクト同時起動）
- [ ] 自動ヘルスチェック

## ライセンス

個人用dotfiles - 自由に改変してください

## 貢献

このリポジトリは個人用ですが、アイデアや改善提案は歓迎します。

---

**最終更新**: 2026-03-27
**メンテナ**: Claude Code + User
