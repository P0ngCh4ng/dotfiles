# Project Management Guide

このドキュメントでは、`projects.yml` を使った統合プロジェクト管理システムの使い方を説明します。

## 概要

このdotfilesリポジトリは、PC上の全プロジェクトを一元管理するシステムを提供します。

**管理対象**:
- ✅ プロジェクトのパスと説明
- ✅ 使用ポートの割り当てと競合チェック
- ✅ データベース設定（接続情報、バックアップ設定）
- ✅ 技術スタック（使用言語・フレームワーク）
- ✅ Docker統合（コンテナ管理）

---

## ファイル構成

```
~/dotfiles/
├── projects.yml           # 実際のプロジェクト設定（gitignored）
├── projects.yml.example   # テンプレート（git管理）
├── .zshrc                 # プロジェクト管理関数
├── db.zsh                 # データベース管理関数
└── PROJECT_MANAGEMENT.md  # このファイル
```

---

## セットアップ

### 1. projects.yml の作成

```bash
# テンプレートからコピー
cp ~/dotfiles/projects.yml.example ~/dotfiles/projects.yml

# 既にあれば、そのまま使用
```

### 2. プロジェクト情報の追加

`projects.yml` を編集して、実際のプロジェクトを追加:

```yaml
projects:
  myproject:
    path: ~/projects/myapp
    ports: [3000, 3001]
    description: "My awesome application"
    tech: [node, react, postgresql]
    databases:
      - name: main
        type: postgresql
        host: localhost
        port: 5432
        database: myapp_dev
        user: postgres
        docker:
          container: myapp-postgres
          compose_file: docker-compose.yml
        backup:
          enabled: true
          retention_days: 7
```

### 3. データベースパスワードの設定

```bash
# パスワード環境変数を設定
export MYPROJECT_DB_MAIN_PASSWORD="your_password"

# または、対話的に設定
db-set-password myproject main

# 永続化する場合は ~/.zshenv に追加
echo 'export MYPROJECT_DB_MAIN_PASSWORD="your_password"' >> ~/.zshenv
chmod 600 ~/.zshenv
```

---

## 使用可能なコマンド

### プロジェクト情報管理

#### `pj-info <project-name>`
プロジェクトの詳細情報を表示

```bash
$ pj-info sokko
=== Project: sokko ===
Path: ~/SOKKO
Ports: 5174, 3306
Description: Linear Issue Tracking統合用のMCPサーバー（KENSHO向けカスタマイズ版）
Tech: php, laravel, vue, vite, mysql
Databases: 1 configured

Run 'db-list sokko' for database details
```

#### `port-scan`
現在使用中のポートをスキャン

```bash
$ port-scan
Currently used ports:
3000 node
5174 node
8888 node
```

#### `check-ports`
全プロジェクトのポート割り当てをチェック

```bash
$ check-ports
=== Project Port Assignments ===

📦 dotfiles
  (No ports assigned)

📦 pon
  🟢 Port 8888 (available)

📦 sokko
  🔴 Port 5174 (IN USE)
  🟢 Port 3306 (available)

📦 chatclinic
  🔴 Port 3000 (IN USE)
  🟢 Port 3001 (available)
```

---

### データベース管理

#### Core Operations

##### `db-list <project>`
プロジェクトの全データベースを一覧表示

```bash
$ db-list sokko
=== Databases for project: sokko ===

📦 main (mysql)
  Host: localhost:3306
  Database: laravel
  User: root
  🐳 Container: kensyo-db (running)
  🔑 Password: ✅ Set (SOKKO_DB_MAIN_PASSWORD)
```

##### `db-info <project> <db-name>`
データベースの詳細情報を表示

```bash
$ db-info sokko main
=== Database: main (sokko) ===
Type: mysql
Host: localhost
Port: 3306
Database: laravel
User: root

Docker:
  Container: kensyo-db
  Status: running
  Compose: docker-compose.yml

Backup:
  Enabled: yes
  Retention: 7 days
  Path: ~/dotfiles/etc/db/backup/sokko/main

Environment:
  Password variable: SOKKO_DB_MAIN_PASSWORD
  Status: ✅ Set
```

##### `db-connect <project> <db-name>`
データベースに接続

```bash
$ db-connect sokko main
# MySQL/PostgreSQL の対話型シェルが起動
```

#### Backup & Restore

##### `db-backup <project> <db-name>`
データベースをバックアップ

```bash
$ db-backup sokko main
Creating backup for sokko/main...
✅ Backup created: ~/dotfiles/etc/db/backup/sokko/main/20260324_160000.sql.gz
🗑️  Cleaned up 3 old backup(s)
```

##### `db-restore <project> <db-name> <backup-file|latest>`
バックアップから復元

```bash
$ db-restore sokko main latest
⚠️  WARNING: This will OVERWRITE the current database!
Database: laravel
Backup file: ~/dotfiles/etc/db/backup/sokko/main/20260324_160000.sql.gz
Are you sure? Type 'yes' to continue: yes
Restoring database...
✅ Database restored successfully
```

#### Docker Management

##### `db-status <project>`
データベースコンテナのステータスを表示

```bash
$ db-status sokko
=== Database Container Status: sokko ===

📦 main (kensyo-db)
  Status: ✅ Running
  Container: kensyo-db
```

##### `db-start <project> [db-name]`
データベースコンテナを起動

```bash
$ db-start sokko
Starting database containers for sokko...
✅ Started container: kensyo-db

$ db-start sokko main
Starting database: main (kensyo-db)...
Using docker-compose file: /Users/pongchang/SOKKO/docker-compose.yml
✅ Container kensyo-db started
```

##### `db-stop <project> [db-name]`
データベースコンテナを停止

```bash
$ db-stop sokko main
Stopping database: main (kensyo-db)...
✅ Container kensyo-db stopped
```

#### Security & Testing

##### `db-set-password <project> <db-name>`
パスワードを安全に設定

```bash
$ db-set-password sokko main
Enter password (input hidden): ********
Confirm password: ********
✅ Password set for current session
ℹ️  To persist, add to ~/.zshenv:
export SOKKO_DB_MAIN_PASSWORD="YOUR_PASSWORD_HERE"
```

##### `db-test-connection <project> <db-name>`
データベース接続をテスト

```bash
$ db-test-connection sokko main
Testing connection to sokko/main...
✅ Connection successful
```

---

## 管理されているプロジェクト

### dotfiles
- **パス**: ~/dotfiles
- **ポート**: なし
- **説明**: Personal dotfiles and PC management hub
- **技術**: zsh, emacs, make

### pon
- **パス**: ~/pon
- **ポート**: 8888
- **説明**: PON! - Dynamic MCP Server Orchestration Platform
- **技術**: react, primereact, webpack, mcp
- **DB**: なし

### sokko
- **パス**: ~/SOKKO
- **ポート**: 5174 (vite), 3306 (MySQL)
- **説明**: Linear Issue Tracking統合用のMCPサーバー（KENSHO向けカスタマイズ版）
- **技術**: php, laravel, vue, vite, mysql
- **DB**: MySQL (laravel) - Docker: kensyo-db

### chatclinic
- **パス**: ~/ChatClinic
- **ポート**: 3000 (main), 3001 (payment)
- **説明**: ClinicTalk - オンライン診療予約・相談システム
- **技術**: typescript, node, express, mysql
- **DB**: MySQL (chatclinic)

### onlinemedic
- **パス**: ~/onlinemedic
- **ポート**: 3005
- **説明**: ONLINE MEDIC - オンライン診療サービス
- **技術**: typescript, node, express, prisma, mysql
- **DB**: MySQL (chatclinic) - ChatClinicとDB共有

### hojocon
- **パス**: ~/hojocon
- **ポート**: 3006
- **説明**: 補助金申請管理システム
- **技術**: nextjs, react, typescript, drizzle

---

## ワークフロー例

### 新しいプロジェクトで作業を開始

```bash
# 1. プロジェクト情報を確認
pj-info myproject

# 2. データベース状態をチェック
db-status myproject

# 3. 必要ならDBコンテナを起動
db-start myproject

# 4. 接続テスト
db-test-connection myproject main

# 5. プロジェクトディレクトリに移動
cd ~/projects/myproject
```

### マイグレーション前のバックアップ

```bash
# 1. 安全のためバックアップ
db-backup myproject main

# 2. マイグレーション実行
npm run migrate

# 3. 接続確認
db-test-connection myproject main

# もし問題があれば復元
# db-restore myproject main latest
```

### ポート競合の解決

```bash
# 1. 全プロジェクトのポート状態を確認
check-ports

# 2. 使用中のポートを特定
port-scan

# 3. projects.yml でポート番号を変更

# 4. 該当プロジェクトの .env や設定ファイルも更新
vim ~/myproject/.env  # PORT=新しいポート番号
```

### 他のマシンへの移行

```bash
# 1. dotfilesをクローン
git clone https://github.com/yourusername/dotfiles.git ~/dotfiles

# 2. セットアップ
cd ~/dotfiles
make install

# 3. projects.yml を新環境用に調整
vim ~/dotfiles/projects.yml

# 4. パスワードを設定
db-set-password myproject main

# 5. データベースを復元（バックアップがあれば）
db-restore myproject main latest
```

---

## セキュリティ

### パスワード管理

**❌ やってはいけないこと**:
- projects.yml にパスワードを書かない
- コマンドライン引数でパスワードを渡さない
- パスワードを git にコミットしない

**✅ 正しい方法**:
- 環境変数でパスワードを管理
- ~/.zshenv に保存（chmod 600 必須）
- パスワードマネージャーを使用（推奨）

### パスワード命名規則

```bash
${PROJECT名(大文字)}_DB_${DB名(大文字)}_PASSWORD

# 例:
export SOKKO_DB_MAIN_PASSWORD="secret123"
export CHATCLINIC_DB_MAIN_PASSWORD="password456"
export ONLINEMEDIC_DB_MAIN_PASSWORD="secure789"
```

---

## トラブルシューティング

### データベースに接続できない

```bash
# 1. パスワードが設定されているか確認
db-info myproject main

# 2. コンテナが起動しているか確認
db-status myproject

# 3. コンテナを起動
db-start myproject main

# 4. 接続テスト
db-test-connection myproject main
```

### ポートが競合している

```bash
# 1. 競合を確認
check-ports

# 2. 使用中のプロセスを確認
lsof -iTCP -sTCP:LISTEN -n -P | grep <port>

# 3. projects.yml でポート番号を変更

# 4. アプリケーションの設定ファイルも更新
```

### バックアップから復元できない

```bash
# 1. バックアップファイルを確認
ls -lh ~/dotfiles/etc/db/backup/myproject/main/

# 2. 特定のバックアップを指定
db-restore myproject main 20260324_160000.sql.gz

# 3. データベースが存在するか確認
db-connect myproject main
# (接続後) SHOW DATABASES;
```

---

## 関連ドキュメント

- **CLAUDE.md**: プロジェクト全体のドキュメント
- **~/.claude/rules/database-management.md**: DB管理のルール
- **~/.claude/skills/db-management/SKILL.md**: DB実装の詳細
- **~/.claude/skills/db-management/examples/**: 設定例と使用例

---

## 今後の拡張予定

- [ ] Git ブランチトラッキング
- [ ] 依存関係管理
- [ ] クイックナビゲーションショートカット
- [ ] バッチ操作（複数プロジェクト同時起動など）
- [ ] MongoDB/Redis のフルサポート
- [ ] 自動ヘルスチェック

---

**最終更新**: 2026-03-24
**メンテナ**: Claude Code + User
