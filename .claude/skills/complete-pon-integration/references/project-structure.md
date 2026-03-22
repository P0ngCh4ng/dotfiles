# 完全PON統合システム - プロジェクト構造

## ディレクトリ構造

```
manual-pon/
├── src/
│   ├── components/              # UIコンポーネント
│   │   ├── App.jsx                 # メインアプリ（PonDataProvider配置）
│   │   ├── AutoPonExecutor.jsx     # Auto PON自動実行
│   │   └── PonFlowVisualizer.jsx   # PONフロー可視化
│   │
│   ├── contexts/                # React Context
│   │   └── PonDataContext.jsx      # PONデータ共有Context
│   │
│   ├── types/                   # 型定義
│   │   └── PonDataTypes.js         # PON標準データ型
│   │
│   ├── services/                # ビジネスロジック
│   │   ├── llmService.js           # LLM API統合
│   │   └── ponOrchestrator.js      # PON実行オーケストレーター
│   │
│   ├── db-pon/                  # DB PON!モジュール
│   │   └── src/components/DBPon.jsx
│   │
│   ├── ui-pon/                  # UI PON!モジュール
│   │   └── src/components/UIPon.jsx
│   │
│   ├── md-pon/                  # MD PON!モジュール（新規）
│   │   └── src/components/MDPon.jsx
│   │
│   ├── test-pon/                # Test PON!モジュール
│   │   └── src/components/SmartTestPon.jsx
│   │
│   ├── system-pon/              # System PON!モジュール（新規）
│   │   └── src/components/SystemPon.jsx
│   │
│   └── e2e/                     # Playwright E2Eテスト（新規）
│       └── complete-pon-flow.spec.js
│
├── playwright.config.js         # Playwright設定（新規）
├── package.json                 # 依存関係
└── server.js                    # Express開発サーバー
```

## 主要ファイル

### 新規作成ファイル（9個）

1. **contexts/PonDataContext.jsx** - PONデータ共有Context
2. **types/PonDataTypes.js** - PON標準データ型定義
3. **md-pon/src/components/MDPon.jsx** - MD PON!コンポーネント
4. **system-pon/src/components/SystemPon.jsx** - System PON!コンポーネント
5. **components/AutoPonExecutor.jsx** - Auto PON Executor
6. **components/PonFlowVisualizer.jsx** - PON Flow Visualizer
7. **services/llmService.js** - LLM統合サービス
8. **services/ponOrchestrator.js** - PON実行オーケストレーター
9. **e2e/complete-pon-flow.spec.js** - E2Eテスト

### 修正ファイル（4個）

1. **components/App.jsx** - PonDataProvider追加、新タブ追加
2. **db-pon/src/components/DBPon.jsx** - Context統合、data-testid追加
3. **ui-pon/src/components/UIPon.jsx** - Context統合、自動生成トリガー
4. **test-pon/src/components/SmartTestPon.jsx** - Context統合

## 依存関係

### 新規追加パッケージ

```json
{
  "dependencies": {
    "react-markdown": "^9.0.1",
    "remark-gfm": "^4.0.0",
    "jszip": "^3.10.1",
    "file-saver": "^2.0.5"
  },
  "devDependencies": {
    "@playwright/test": "^1.40.0",
    "playwright": "^1.40.0"
  }
}
```

## データフロー

```
┌─────────────┐
│  DB PON!    │ → dataModel
└─────────────┘
       ↓
┌─────────────┐
│  UI PON!    │ → uiScreens
└─────────────┘
       ↓
┌─────────────┐
│  MD PON!    │ → specification
└─────────────┘
       ↓
┌─────────────┐
│ Test PON!   │ → testCases
└─────────────┘
       ↓
┌─────────────┐
│System PON!  │ → generatedCode (ZIP)
└─────────────┘
```

## LocalStorageキー

- `pon-data` - PON全データ（Context state）
- `manual_pon_current_project` - 現在のプロジェクトID
- `manual_pon_projects` - プロジェクト一覧
- `manual_pon_prompts` - プロンプト履歴

## テスト構成

### E2Eテスト（10個）

1. PON Platform基本表示
2. デバッグプロジェクトバッジ表示
3. DB→UI→MD自動データフロー
4. MD PON仕様書生成・ダウンロード
5. System PONコード生成・ファイル一覧表示
6. Auto PON Executor UI表示
7. 要件入力による実行ボタン有効化
8. Auto PON実行フロー
9. LocalStorageデータ永続化
10. データクリア機能

**合格率: 50%（5/10）**

成功: Auto PON全機能、データ永続化
失敗: タイミング問題、UI要素検証

## コード統計

- **新規実装行数**: 約2,500行
- **総ファイル数**: 113個（JSX/JS）
- **新規コンポーネント**: 6個
- **新規サービス**: 2個
- **E2Eテストケース**: 10個

## パフォーマンス

- **Webpackビルド**: 1.51 MiB（警告あり、動作OK）
- **ビルド時間**: 約6秒
- **起動時間**: 約2秒
- **PON実行時間**: 約10-15秒（全5PON）
