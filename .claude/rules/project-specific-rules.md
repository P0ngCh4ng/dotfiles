# Project-Specific Rules

**このファイルは `~/dotfiles/projects.yml` の内容を元に、各プロジェクトの詳細設定とルールを定義しています。**

**重要**: プロジェクトで作業する際は、必ずこのファイルの該当セクションを確認してください。

---

## dotfiles

**パス**: `~/dotfiles`
**ポート**: なし
**技術**: zsh, emacs, make

### 概要
個人用dotfilesとPC管理のハブ。全プロジェクトの中央設定を管理。

### データベース
なし

### 特記事項
- `projects.yml` - 全プロジェクトの一元管理ファイル（gitignored、ローカル専用）
- `db.zsh` - データベース管理関数（全プロジェクトで使用）
- `.zshrc` - ポート管理関数とDB関数を提供
- Makefileで `make install`, `make deploy`, `make init` が使用可能

### 推奨ワークフロー
1. 変更前にバックアップ: `git status` で確認
2. テスト: `make deploy` でシンボリックリンクテスト
3. コミット前に `make list` で変更確認

---

## pon

**パス**: `~/pon`
**ポート**: 8888 (webpack devServer)
**技術**: react, primereact, webpack, mcp

### 概要
PON! - Dynamic MCP Server Orchestration Platform

### データベース
なし

### 開発サーバー
- **ポート 8888**: Webpack Dev Server
- 起動: `npm run dev` または `npm start`
- URL: `http://localhost:8888`

### 特記事項
- MCPサーバーオーケストレーションプラットフォーム
- PrimeReact使用（UIコンポーネント）
- devServerの設定はwebpack.config.jsで管理

### ポート競合時の対応
```bash
# ポート確認
check-ports

# ポート8888を使用中のプロセスを確認
lsof -i :8888

# 必要に応じて別ポートに変更（webpack.config.js）
```

---

## sokko (SOKKO)

**パス**: `~/SOKKO`
**ポート**: 5174 (Vite), 3306 (MySQL)
**技術**: php, laravel, vue, vite, mysql

### 概要
Linear Issue Tracking統合用のMCPサーバー（KENSHO向けカスタマイズ版）

### データベース

#### main (MySQL)
- **タイプ**: mysql
- **ホスト**: localhost
- **ポート**: 3306
- **データベース名**: laravel
- **ユーザー**: root
- **パスワード**: 環境変数 `SOKKO_DB_MAIN_PASSWORD`
- **Docker**:
  - コンテナ名: `kensyo-db`
  - Compose ファイル: `docker-compose.yml`
- **バックアップ**:
  - 有効: true
  - 保持期間: 7日間

### 開発サーバー
- **ポート 5174**: Vite Dev Server (フロントエンド)
- **ポート 3306**: MySQL Database

### 推奨ワークフロー
1. **起動前チェック**:
   ```bash
   pj-info sokko
   db-status sokko
   check-ports
   ```

2. **データベース起動**:
   ```bash
   db-start sokko
   db-test-connection sokko main
   ```

3. **開発サーバー起動**:
   ```bash
   # Laravel
   php artisan serve

   # Vite (フロントエンド)
   npm run dev  # ポート 5174
   ```

4. **マイグレーション前のバックアップ**:
   ```bash
   db-backup sokko main
   php artisan migrate
   ```

### パスワード設定
```bash
# 初回セットアップ
db-set-password sokko main

# または ~/.zshenv に追加
echo 'export SOKKO_DB_MAIN_PASSWORD="your_password"' >> ~/.zshenv
chmod 600 ~/.zshenv
```

### ポート競合時の対応
- **5174競合**: Viteの設定 `vite.config.js` でポート変更
- **3306競合**: 別のMySQLが起動している可能性。`db-status` で確認

---

## chatclinic (ChatClinic)

**パス**: `~/ChatClinic`
**ポート**: 3000 (main), 3001 (payment)
**技術**: typescript, node, express, mysql

### 概要
ClinicTalk - オンライン診療予約・相談システム

### データベース

#### main (MySQL)
- **タイプ**: mysql
- **ホスト**: localhost
- **ポート**: 3306
- **データベース名**: chatclinic
- **ユーザー**: root
- **パスワード**: 環境変数 `CHATCLINIC_DB_MAIN_PASSWORD`
- **バックアップ**:
  - 有効: true
  - 保持期間: 14日間

### 開発サーバー
- **ポート 3000**: メインアプリケーション
- **ポート 3001**: 決済サーバー

### 推奨ワークフロー
1. **起動前チェック**:
   ```bash
   pj-info chatclinic
   db-status chatclinic
   check-ports
   ```

2. **データベース起動**:
   ```bash
   db-start chatclinic  # Dockerコンテナがある場合
   # または既存のMySQLを使用
   db-test-connection chatclinic main
   ```

3. **開発サーバー起動**:
   ```bash
   # メインアプリ（ポート3000）
   npm run dev

   # 決済サーバー（ポート3001）
   npm run payment-server
   ```

### パスワード設定
```bash
db-set-password chatclinic main
```

### 特記事項
- **onlinemedic** と同じデータベース（chatclinic）を共有
- 決済サーバーは別ポート（3001）で稼働
- 本番環境への影響に注意：バックアップ保持期間14日

### ポート競合時の対応
```bash
# ポート3000/3001の使用状況確認
check-ports
lsof -i :3000
lsof -i :3001

# onlinemedicとの競合に注意
pj-info onlinemedic
```

---

## onlinemedic

**パス**: `~/onlinemedic`
**ポート**: 3005
**技術**: typescript, node, express, prisma, mysql

### 概要
ONLINE MEDIC - オンライン診療サービス

### データベース

#### main (MySQL)
- **タイプ**: mysql
- **ホスト**: localhost
- **ポート**: 3306
- **データベース名**: chatclinic ⚠️ **ChatClinicと共有**
- **ユーザー**: root
- **パスワード**: 環境変数 `ONLINEMEDIC_DB_MAIN_PASSWORD`
- **バックアップ**:
  - 有効: true
  - 保持期間: 14日間

### 開発サーバー
- **ポート 3005**: メインアプリケーション（ChatClinicとの競合回避のため3000から変更）

### ⚠️ 重要な注意事項
**ChatClinicとデータベースを共有しています**

- マイグレーション実行前に**必ずバックアップ**
- データベース操作は両プロジェクトに影響
- Prismaスキーマ変更は慎重に

### 推奨ワークフロー
1. **起動前チェック**:
   ```bash
   pj-info onlinemedic
   db-status onlinemedic

   # ChatClinicの状態も確認
   pj-info chatclinic
   ```

2. **データベース操作前のバックアップ（必須）**:
   ```bash
   # 両プロジェクト共有DBのため特に重要
   db-backup onlinemedic main
   ```

3. **開発サーバー起動**:
   ```bash
   npm run dev  # ポート 3005
   ```

4. **Prismaマイグレーション**:
   ```bash
   # 必ずバックアップ後に実行
   db-backup onlinemedic main
   npx prisma migrate dev
   ```

### パスワード設定
```bash
db-set-password onlinemedic main
```

### ポート競合時の対応
- **3005競合**: package.jsonまたは起動スクリプトでポート変更
- 元々3000を使用予定だったが、ChatClinicとの競合回避で3005に変更済み

---

## hojocon

**パス**: `~/hojocon`
**ポート**: 3006 (Next.js)
**技術**: nextjs, react, typescript, drizzle

### 概要
補助金申請管理システム

### データベース
なし（またはDrizzle ORMで管理）

### 開発サーバー
- **ポート 3006**: Next.js Dev Server
- 起動: `npm run dev`
- URL: `http://localhost:3006`

### 特記事項
- Next.jsのデフォルトポート3000を回避するため3006を使用
- Drizzle ORM使用（DBスキーマ管理）
- `get-port.js` による動的ポート割り当て機能あり

### 推奨ワークフロー
1. **起動前チェック**:
   ```bash
   pj-info hojocon
   check-ports
   ```

2. **開発サーバー起動**:
   ```bash
   npm run dev  # ポート 3006
   ```

### ポート競合時の対応
```bash
# ポート3006の使用状況確認
check-ports
lsof -i :3006

# 動的ポート割り当てが有効な場合は自動で回避
```

---

## 全プロジェクト共通ルール

### セッション開始時の必須アクション

**ALWAYS** do this at the start of EVERY session:

1. **プロジェクト情報を読み込む**:
   ```bash
   pj-info <project>
   ```

2. **ポート競合を確認**:
   ```bash
   check-ports
   ```

3. **データベース状態を確認**（DBがある場合）:
   ```bash
   db-status <project>
   db-list <project>
   ```

### データベース操作の安全ルール

**CRITICAL**: 以下の操作前には**必ず**バックアップ:

- マイグレーション実行
- スキーマ変更
- 大量データ削除
- プロダクションデータの操作

```bash
# バックアップコマンド
db-backup <project> <db-name>

# 復元が必要な場合
db-restore <project> <db-name> latest
```

### ポート競合の解決手順

1. **現在の使用状況を確認**:
   ```bash
   check-ports
   port-scan
   ```

2. **競合プロジェクトを特定**:
   ```bash
   lsof -i :<port>
   ```

3. **解決策を選択**:
   - 不要なプロジェクトを停止
   - 新しいプロジェクトのポート番号を変更
   - プロジェクト設定ファイルでポート調整

### パスワード管理

**NEVER** store passwords in:
- projects.yml
- Code files
- Git commits
- Shell history

**ALWAYS** use environment variables:
```bash
# Format: ${PROJECT^^}_DB_${DB_NAME^^}_PASSWORD
export SOKKO_DB_MAIN_PASSWORD="secret"
export CHATCLINIC_DB_MAIN_PASSWORD="secret"
export ONLINEMEDIC_DB_MAIN_PASSWORD="secret"
```

Store in `~/.zshenv` or use `db-set-password`:
```bash
db-set-password <project> <db-name>
```

---

## トラブルシューティング

### "Operation not permitted" エラー

cage のサンドボックス制限が原因。

**解決方法**:
1. `~/.config/cage/presets.yaml` に該当パスを追加
2. Emacs外のターミナルで実行
3. `claude-code-toggle-cage` でcageを一時的に無効化

### データベース接続エラー

```bash
# 診断手順
db-test-connection <project> <db-name>
db-info <project> <db-name>
db-status <project>

# よくある原因
# 1. パスワード未設定
db-set-password <project> <db-name>

# 2. コンテナ未起動
db-start <project>

# 3. 環境変数が読み込まれていない
source ~/.zshenv
```

### ポート競合エラー "address already in use"

```bash
# どのプロジェクトがポートを使用中か確認
check-ports

# 該当ポートのプロセスを確認
lsof -i :<port>

# 安全に停止
# (プロジェクトの停止コマンドを使用)
```

---

## 関連ドキュメント

- **プロジェクト管理**: `~/.claude/rules/project-management.md`
- **データベース管理**: `~/.claude/rules/database-management.md`
- **Projects設定**: `~/dotfiles/projects.yml`
- **Dotfiles管理**: `~/dotfiles/CLAUDE.md`
- **DB管理実装**: `~/.claude/skills/db-management/SKILL.md`

---

## 更新履歴

- **2026-03-24**: 初版作成 - 全6プロジェクトの詳細情報を集約
