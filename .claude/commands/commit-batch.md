# Batch Commit and Push

変更されたファイルを4〜5ファイルごとにグループ化し、Conventional Commits形式でコミット・プッシュします。

## 手順

1. `git status` を実行して変更ファイルを確認
2. `git diff` を実行して変更内容を確認
3. 変更されたファイルを内容に基づいて4〜5ファイルのグループに分割
4. 各グループについて：
   - 変更内容を分析し、適切なConventional Commitタイプを決定：
     * `feat:` - 新機能の追加
     * `fix:` - バグ修正
     * `refactor:` - リファクタリング
     * `docs:` - ドキュメント変更
     * `style:` - コードスタイルの変更（フォーマット、セミコロンなど）
     * `test:` - テストの追加・変更
     * `chore:` - ビルドプロセスやツールの変更
     * `perf:` - パフォーマンス改善
   - そのグループのファイルのみを `git add` でステージング
   - 変更内容を簡潔に説明するコミットメッセージを作成（形式: `type: 簡潔な説明`）
   - `git commit -m "メッセージ"` でコミット
5. すべてのグループをコミットした後、`git push` で一括プッシュ

## 注意事項

- コミットメッセージは英語で簡潔に記述
- 各コミットは論理的に関連するファイルをまとめる
- コミットメッセージの例:
  - `feat: add user authentication feature`
  - `fix: resolve memory leak in data processing`
  - `refactor: simplify component structure`
