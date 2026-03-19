;;; claude-code-help-content.el --- Claude Code workflow help content -*- lexical-binding: t; -*-

;; Copyright (C) 2026

;; Author: Your Name
;; Keywords: tools, help

;;; Commentary:

;; This file defines the workflow content for Claude Code help system.
;; It contains various development workflows and best practices.

;;; Code:

(defconst claude-code-workflows
  '((feature-development
     :title "🚀 新機能開発フロー"
     :description "新しい機能を追加する際の推奨ワークフロー"
     :steps ("1. 要件の明確化"
             "   - 曖昧な場合: interviewer エージェントで要件整理"
             "   - 明確な場合: 次のステップへ"
             ""
             "2. 設計と計画"
             "   - コマンド: /plan"
             "   - planner エージェントが自動起動"
             "   - 実装計画を確認して承認"
             ""
             "3. 実装"
             "   - アプローチ: /tdd でテスト駆動開発"
             "   - 既存コードの理解: Read, Grep, mcp__serena__* ツール活用"
             "   - 並列処理: 独立した操作は同時実行"
             ""
             "4. コードレビュー"
             "   - 必須: code-reviewer エージェント起動"
             "   - 品質、セキュリティ、保守性をチェック"
             ""
             "5. ドキュメント更新"
             "   - doc-updater エージェントで CODEMAPS と README 更新"
             ""
             "6. コミットとPR作成"
             "   - コマンド: /commit または gacp 関数"
             "   - PR作成: gh pr create コマンド"))

    (bug-fix
     :title "🐛 バグ修正フロー"
     :description "バグを特定して修正する際のワークフロー"
     :steps ("1. 問題の再現"
             "   - エラーメッセージ、スタックトレースを確認"
             "   - 再現手順を明確化"
             ""
             "2. 原因調査"
             "   - Grep で関連コード検索"
             "   - Read で該当ファイル読み込み"
             "   - mcp__serena__find_symbol でシンボル追跡"
             "   - mcp__serena__find_referencing_symbols で参照箇所確認"
             ""
             "3. 修正実装"
             "   - Edit で最小限の変更"
             "   - テストケース追加（再発防止）"
             ""
             "4. 検証"
             "   - テスト実行: Bash で npm test / pytest など"
             "   - code-reviewer エージェントでレビュー"
             ""
             "5. コミット"
             "   - コマンド: /commit"
             "   - メッセージ形式: 'fix: [問題の説明]'"))

    (refactoring
     :title "♻️  リファクタリングフロー"
     :description "コードの構造改善を行う際のワークフロー"
     :steps ("1. 計画立案"
             "   - 必須: /plan でリファクタリング計画作成"
             "   - planner エージェントが依存関係を分析"
             ""
             "2. 現状把握"
             "   - mcp__serena__get_symbols_overview でファイル構造確認"
             "   - mcp__serena__find_referencing_symbols で影響範囲調査"
             ""
             "3. テスト準備"
             "   - 既存テストの実行と確認"
             "   - 必要に応じて追加テスト作成"
             ""
             "4. 段階的リファクタリング"
             "   - mcp__serena__rename_symbol でシンボル一括リネーム"
             "   - mcp__serena__replace_symbol_body でシンボル本体置換"
             "   - 各段階でテスト実行"
             ""
             "5. レビューとドキュメント更新"
             "   - code-reviewer エージェント"
             "   - doc-updater エージェントでドキュメント同期"
             ""
             "6. コミット"
             "   - メッセージ形式: 'refactor: [改善内容]'"))

    (ui-development
     :title "🎨 UI開発フロー"
     :description "UIコンポーネントやページを開発する際のワークフロー"
     :steps ("1. ペルソナとデザイン要件定義"
             "   - ターゲットユーザーの明確化"
             "   - デザインパターンの選択"
             ""
             "2. UI生成"
             "   - ui-generator エージェント: ペルソナベースでUI生成"
             "   - または ui-orchestrator: 生成とレビューを一括実行"
             ""
             "3. 実装"
             "   - コンポーネント作成"
             "   - スタイリング適用"
             ""
             "4. 品質チェック（Playwright MCP使用）"
             "   - ui-accessibility-checker: WCAG 2.1準拠確認"
             "   - ui-responsive-checker: マルチデバイス互換性"
             "   - ui-layout-checker: レイアウト、スペーシング"
             "   - ui-consistency-checker: デザイン一貫性"
             ""
             "5. 総合レビュー"
             "   - ui-reviewer: 包括的品質チェック"
             "   - design-review: PR向けデザインレビュー"
             ""
             "6. 修正と最終確認"
             "   - ui-decision-maker: 修正優先順位決定"
             "   - 自動修正可能な問題は即座に対応"))

    (code-review
     :title "👀 コードレビューフロー"
     :description "コードの品質確認を行う際のワークフロー"
     :steps ("1. 変更内容の把握"
             "   - git diff で差分確認"
             "   - 変更ファイル一覧確認: git status"
             ""
             "2. 自動レビュー"
             "   - 必須: code-reviewer エージェント起動"
             "   - 品質、セキュリティ、保守性を評価"
             ""
             "3. UIレビュー（UI変更がある場合）"
             "   - design-review エージェント"
             "   - Playwright MCPでブラウザテスト自動実行"
             ""
             "4. 修正対応"
             "   - レビュー指摘事項の修正"
             "   - 再度レビューエージェント実行"
             ""
             "5. 承認"
             "   - すべてのチェックがパス"
             "   - ドキュメントが更新されている"))

    (documentation
     :title "📚 ドキュメント更新フロー"
     :description "プロジェクトドキュメントを更新する際のワークフロー"
     :steps ("1. コードマップ更新"
             "   - コマンド: /update-codemaps"
             "   - doc-updater エージェントが自動実行"
             "   - docs/CODEMAPS/* が生成される"
             ""
             "2. README更新"
             "   - コマンド: /update-docs"
             "   - プロジェクト概要、使い方、構成を同期"
             ""
             "3. CLAUDE.md の保守"
             "   - プロジェクト固有のパターン記録"
             "   - 新しい慣習やルールを追加"
             "   - 手動更新が必要"
             ""
             "4. メモリの活用"
             "   - mcp__serena__write_memory: 将来のタスクに役立つ情報を保存"
             "   - mcp__serena__list_memories: 既存メモリ確認"
             "   - トピック別整理: 'auth/login/logic' 形式"
             ""
             "5. コミット"
             "   - メッセージ形式: 'docs: [更新内容]'"))

    (exploration
     :title "🔍 コードベース探索フロー"
     :description "既存コードを理解する際のワークフロー"
     :steps ("1. 全体構造の把握"
             "   - Glob でファイルパターン検索"
             "   - mcp__serena__list_dir で再帰的にディレクトリ一覧"
             ""
             "2. ファイル単位の理解"
             "   - mcp__serena__get_symbols_overview: シンボル一覧取得"
             "   - depth パラメータで階層深度指定"
             ""
             "3. シンボル検索"
             "   - mcp__serena__find_symbol: 名前パスパターンで検索"
             "   - substring_matching=true で部分一致"
             "   - include_body=true で実装も取得"
             ""
             "4. 依存関係の追跡"
             "   - mcp__serena__find_referencing_symbols: 参照元を発見"
             "   - コードスニペット付きで参照箇所確認"
             ""
             "5. パターン検索"
             "   - mcp__serena__search_for_pattern: 正規表現で柔軟検索"
             "   - restrict_search_to_code_files でコードファイルに限定"
             "   - paths_include_glob でファイル絞り込み"
             ""
             "6. メモリ参照"
             "   - mcp__serena__read_memory: 過去の知見を活用"
             "   - 関連トピックのメモリを確認"))

    (agent-usage
     :title "🤖 エージェント活用ガイド"
     :description "各種エージェントの使い分けと起動タイミング"
     :steps ("【自動起動エージェント - 即座に起動】"
             ""
             "planner"
             "  - タイミング: 機能追加、アーキテクチャ変更、複雑なリファクタリング"
             "  - キーワード: 計画/plan/設計"
             "  - コマンド: /plan"
             ""
             "code-reviewer"
             "  - タイミング: コード記述/変更の直後（必須）"
             "  - すべてのコード変更に使用"
             ""
             "doc-updater"
             "  - タイミング: コードベース構造変更時"
             "  - コマンド: /update-codemaps, /update-docs"
             ""
             "【要件整理エージェント】"
             ""
             "interviewer"
             "  - 曖昧な要望を構造化した要件に変換"
             "  - WHATとHOWを適切な専門エージェントに振り分け"
             ""
             "requirements-interviewer"
             "  - 「何を作るか」の明確化"
             "  - 問題、ユーザー、ゴール、成功基準の整理"
             ""
             "implementation-bridge"
             "  - 「どう実装するか」の構造化"
             "  - 要件が明確な場合に実装手順を整理"
             ""
             "【UI開発エージェント】"
             ""
             "ui-orchestrator"
             "  - ペルソナベースUI生成 + 包括的品質チェック"
             "  - Playwright MCP でブラウザ自動化"
             ""
             "ui-generator"
             "  - ペルソナと要件からUIコンポーネント生成"
             ""
             "ui-reviewer"
             "  - Playwright で包括的UI品質チェック"
             ""
             "ui-accessibility-checker"
             "  - WCAG 2.1準拠検証"
             ""
             "ui-responsive-checker"
             "  - マルチデバイス互換性テスト"
             ""
             "ui-layout-checker"
             "  - 要素配置、スペーシング、視覚階層"
             ""
             "ui-consistency-checker"
             "  - 色、タイポグラフィ、スペーシング一貫性"
             ""
             "ui-decision-maker"
             "  - UIレビュー結果の優先順位決定"
             ""
             "design-review"
             "  - PRのデザイン包括レビュー"
             ""
             "【その他の専門エージェント】"
             ""
             "general-purpose"
             "  - 複雑な多段階リサーチ、コード検索"
             "  - 最初の数回で見つからない可能性がある場合"
             ""
             "emacs-verifier"
             "  - Emacs設定の包括的検証"
             "  - エラー/警告の自動修正"
             "  - ZERO エラー・警告まで反復"))

    (best-practices
     :title "💡 ベストプラクティス"
     :description "効率的な開発のための推奨事項"
     :steps ("【効率化原則】"
             ""
             "1. 並列実行"
             "   - 独立した操作は同時実行"
             "   - 例: 複数ファイルの Read, 複数パターンの Grep"
             ""
             "2. ツール選択"
             "   - 専用ツールを優先（Bash より Read/Edit/Write）"
             "   - Serena MCP ツールで段階的に情報取得"
             "   - ファイル全体読み込みは最終手段"
             ""
             "3. コンテキスト管理"
             "   - CLAUDE.md でプロジェクト固有パターン記録"
             "   - mcp__serena__write_memory で知見保存"
             "   - グローバル知見は 'global/' プレフィックス"
             ""
             "【コード品質】"
             ""
             "1. 理解してから変更"
             "   - 既存コードを必ず理解"
             "   - 影響範囲を調査（find_referencing_symbols）"
             ""
             "2. テスト駆動"
             "   - /tdd でテスト駆動開発"
             "   - 80%以上のカバレッジ目標"
             ""
             "3. 段階的実装"
             "   - 大きな変更は小さく分割"
             "   - 各段階でテストとレビュー"
             ""
             "【エージェント活用】"
             ""
             "1. 計画段階での使用"
             "   - コード記述前に /plan 実行"
             "   - 曖昧な要件は interviewer で整理"
             ""
             "2. 品質保証"
             "   - すべてのコード変更後に code-reviewer"
             "   - UI変更時は design-review"
             ""
             "3. 複雑タスクの委譲"
             "   - 検索が複数回必要: general-purpose エージェント"
             "   - Emacs設定変更: emacs-verifier エージェント"
             ""
             "【トラブルシューティング】"
             ""
             "1. ビルドエラー"
             "   - Bash でビルドコマンド実行"
             "   - エラーメッセージから原因特定"
             "   - Grep で関連コード検索"
             ""
             "2. 依存関係問題"
             "   - find_referencing_symbols で影響範囲確認"
             "   - 後方互換性を保つか全参照を更新"
             ""
             "3. パフォーマンス"
             "   - 検索範囲を relative_path で限定"
             "   - max_answer_chars で出力制限"
             "   - depth パラメータで階層制限"))))

(defconst claude-code-key-commands
  '((:category "Planning & Design"
     :commands (("/plan" . "実装計画の作成（planner エージェント起動）")
                ("/interview" . "要件整理のためのソクラティック対話")
                ("/tdd" . "テスト駆動開発の強制")))

    (:category "Code Quality"
     :commands (("code-reviewer" . "コードレビュー（必須・自動起動）")
                ("design-review" . "UI/デザイン変更の包括レビュー")))

    (:category "Documentation"
     :commands (("/update-codemaps" . "CODEMAPS 自動生成")
                ("/update-docs" . "README とドキュメント更新")
                ("doc-updater" . "ドキュメント更新エージェント")))

    (:category "Git Operations"
     :commands (("/commit" . "Git コミット作成")
                ("gacp" . "add + commit + push 一括実行（関数）")
                ("gh pr create" . "プルリクエスト作成")))

    (:category "UI Development"
     :commands (("ui-orchestrator" . "UI生成とレビューの一括実行")
                ("ui-generator" . "ペルソナベースUIコンポーネント生成")
                ("ui-reviewer" . "包括的UI品質チェック")
                ("ui-accessibility-checker" . "アクセシビリティ検証")
                ("ui-responsive-checker" . "レスポンシブデザイン検証")))

    (:category "Serena MCP Tools"
     :commands (("mcp__serena__get_symbols_overview" . "ファイルのシンボル概要取得")
                ("mcp__serena__find_symbol" . "シンボル検索（名前パスパターン）")
                ("mcp__serena__find_referencing_symbols" . "シンボルの参照元検索")
                ("mcp__serena__search_for_pattern" . "正規表現パターン検索")
                ("mcp__serena__replace_symbol_body" . "シンボル本体の置換")
                ("mcp__serena__rename_symbol" . "シンボルの一括リネーム")
                ("mcp__serena__write_memory" . "知見をメモリに保存")
                ("mcp__serena__read_memory" . "メモリから知見取得")))))

(provide 'claude-code-help-content)
;;; claude-code-help-content.el ends here
