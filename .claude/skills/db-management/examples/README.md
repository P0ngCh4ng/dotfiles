# Database Management Examples

このディレクトリには、Database Management System の実用的なサンプルが含まれています。

## ファイル一覧

### 1. `example-projects.yml`
**内容**: projects.yml の設定例
**用途**:
- PostgreSQL、MySQL、Redis の設定パターン
- Docker 統合の設定方法
- バックアップ設定の例
- マルチデータベース構成の例
- リモートデータベース接続の例

**使い方**:
```bash
# 参考にして自分の projects.yml に追加
cat example-projects.yml

# または直接コピー（注意：既存の設定を上書き）
cp example-projects.yml ~/dotfiles/projects.yml
```

### 2. `env-setup.sh`
**内容**: 環境変数設定のベストプラクティス
**用途**:
- パスワード環境変数の命名規則
- セキュアな保存方法
- パスワードマネージャーとの統合
- セットアップヘルパー関数

**使い方**:
```bash
# ファイルを読んで理解
cat env-setup.sh

# ヘルパー関数を読み込む
source env-setup.sh

# 対話的にパスワードを設定
setup_db_passwords myapp main
```

### 3. `usage-examples.sh`
**内容**: 全機能の実用的な使用例
**用途**:
- 各コマンドの実行例と出力例
- 一般的なワークフロー
- エラーハンドリング例
- 他ツールとの統合例

**使い方**:
```bash
# コマンドリファレンスとして参照
cat usage-examples.sh

# 特定のセクションを検索
grep -A 5 "db-backup" usage-examples.sh
```

## クイックスタート

1. **設定ファイルの準備**:
```bash
# projects.yml に自分のプロジェクトを追加
vim ~/dotfiles/projects.yml
# または example-projects.yml をベースに
```

2. **パスワードの設定**:
```bash
# env-setup.sh を参考に ~/.zshenv に追加
echo 'export MYAPP_DB_MAIN_PASSWORD="your_password"' >> ~/.zshenv
chmod 600 ~/.zshenv
```

3. **動作確認**:
```bash
# プロジェクトのデータベース一覧
db-list myapp

# 接続テスト
db-test-connection myapp main

# 接続
db-connect myapp main
```

## セキュリティ注意事項

⚠️ **重要**: これらの例ファイルには実際のパスワードを含めないでください

- `example-projects.yml` にはパスワードを書かない（環境変数のみ）
- `env-setup.sh` の例のパスワードは必ず変更する
- これらのファイルを git にコミットする場合、機密情報が含まれていないことを確認

## トラブルシューティング

問題が発生した場合:

1. **SKILL.md の Common Pitfalls セクションを参照**
```bash
cat ../SKILL.md | grep -A 20 "Common Pitfalls"
```

2. **usage-examples.sh のエラーハンドリング例を確認**
```bash
cat usage-examples.sh | grep -A 10 "Error Handling"
```

3. **接続テストで原因を特定**
```bash
db-test-connection myapp main
```

## さらに学ぶ

- **完全なドキュメント**: `../SKILL.md`
- **実装コード**: `~/dotfiles/db.zsh`
- **設定テンプレート**: `~/dotfiles/projects.yml.example`
- **プロジェクトドキュメント**: `~/dotfiles/CLAUDE.md`
