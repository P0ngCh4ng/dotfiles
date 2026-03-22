# Complete PON Integration - 完全PON統合システム実装

## Skill概要

このスキルは、**要件から最終コードまで自動生成する完全PON統合システム**の実装方法を定義します。

DB設計 → UI生成 → 仕様書作成 → テスト生成 → コード出力までの全工程を自動化し、ワンクリックでWebアプリケーションを生成できるシステムを構築します。

## 適用タイミング

- ユーザーが「PONを統合したい」「完全自動化したい」と要求した時
- DB PON、UI PON、MD PON、Test PON、System PONを繋げたい時
- 要件からコードまでの自動生成システムを構築したい時
- Auto PON Executorのような統合実行機能を作りたい時

## アーキテクチャ原則

### 1. Context API によるデータ共有

全PON間でデータを共有するためにReact Context APIを使用：

```javascript
// contexts/PonDataContext.jsx
import React, { createContext, useContext, useState, useEffect } from 'react';

const PonDataContext = createContext();

export const usePonData = () => {
  const context = useContext(PonDataContext);
  if (!context) {
    throw new Error('usePonData must be used within PonDataProvider');
  }
  return context;
};

const initialState = {
  dataModel: null,        // DB PON!の出力
  uiScreens: null,        // UI PON!の出力
  specification: null,    // MD PON!の出力
  testCases: null,        // Test PON!の出力
  generatedCode: null,    // System PON!の出力
  executionStatus: {
    dbPon: { status: 'pending', startTime: null, endTime: null },
    uiPon: { status: 'pending', startTime: null, endTime: null },
    mdPon: { status: 'pending', startTime: null, endTime: null },
    testPon: { status: 'pending', startTime: null, endTime: null },
    systemPon: { status: 'pending', startTime: null, endTime: null },
  },
  errors: [],
};

export const PonDataProvider = ({ children }) => {
  const [ponData, setPonData] = useState(() => {
    const saved = localStorage.getItem('pon-data');
    return saved ? JSON.parse(saved) : initialState;
  });

  // LocalStorage自動保存
  useEffect(() => {
    localStorage.setItem('pon-data', JSON.stringify(ponData));
  }, [ponData]);

  const updatePonData = (key, value) => {
    setPonData(prev => ({ ...prev, [key]: value }));
  };

  const updateExecutionStatus = (ponKey, status, error = null) => {
    setPonData(prev => ({
      ...prev,
      executionStatus: {
        ...prev.executionStatus,
        [ponKey]: {
          status,
          startTime: status === 'running' ? new Date().toISOString() : prev.executionStatus[ponKey]?.startTime,
          endTime: status === 'success' || status === 'error' ? new Date().toISOString() : null,
        },
      },
      errors: error ? [...prev.errors, { ponKey, error, timestamp: new Date().toISOString() }] : prev.errors,
    }));
  };

  const clearPonData = () => {
    setPonData(initialState);
    localStorage.removeItem('pon-data');
  };

  return (
    <PonDataContext.Provider value={{ ponData, updatePonData, updateExecutionStatus, clearPonData }}>
      {children}
    </PonDataContext.Provider>
  );
};
```

### 2. 標準化されたPON出力フォーマット

全PONが同じ形式でデータを出力：

```javascript
// types/PonDataTypes.js

export const PON_TYPES = {
  DB: 'DB_PON',
  UI: 'UI_PON',
  MD: 'MD_PON',
  TEST: 'TEST_PON',
  SYSTEM: 'SYSTEM_PON',
};

/**
 * PON標準出力フォーマット作成
 */
export const createPonOutput = (ponType, data, error = null) => {
  const output = {
    meta: {
      ponType,
      version: '1.0.0',
      generatedAt: new Date().toISOString(),
      projectId: getCurrentProjectId(),
      success: !error,
    },
    data,
  };

  if (error) {
    output.meta.error = error;
  }

  return output;
};

/**
 * PON出力バリデーション
 */
export const validatePonOutput = (output, expectedType) => {
  if (!output || !output.meta) {
    return { valid: false, error: 'Invalid PON output format' };
  }

  if (output.meta.ponType !== expectedType) {
    return {
      valid: false,
      error: `Expected ${expectedType}, got ${output.meta.ponType}`,
    };
  }

  if (!output.meta.success) {
    return {
      valid: false,
      error: output.meta.error || 'Unknown error',
    };
  }

  return { valid: true };
};
```

### 3. 自動データフロー

各PONはuseEffectで前PONの出力を監視し、自動的に処理を開始：

```javascript
// 各PONコンポーネント内
const { ponData, updatePonData } = usePonData();

useEffect(() => {
  // 前PONのデータを検証
  const validation = validatePonOutput(ponData.dataModel, PON_TYPES.DB);

  if (validation.valid && !autoGenerationTriggered) {
    // 自動生成実行
    generateContent();
  }
}, [ponData.dataModel]);
```

## 実装手順

### フェーズ1: MD PON!（仕様書生成）

**依存関係:**
```bash
npm install react-markdown remark-gfm
```

**実装:**

```javascript
// md-pon/src/components/MDPon.jsx
import React, { useState, useEffect } from 'react';
import ReactMarkdown from 'react-markdown';
import remarkGfm from 'remark-gfm';
import { usePonData } from '../../../contexts/PonDataContext';
import { createPonOutput, validatePonOutput, PON_TYPES } from '../../../types/PonDataTypes';

const MDPon = () => {
  const { ponData, updatePonData } = usePonData();
  const [markdown, setMarkdown] = useState('');
  const [isGenerating, setIsGenerating] = useState(false);

  // Mermaid ER図生成
  const generateERDiagram = (dataModel) => {
    if (!dataModel?.data?.tables) return '';

    let mermaid = '```mermaid\nerDiagram\n';
    dataModel.data.tables.forEach(table => {
      mermaid += `    ${table.name} {\n`;
      table.columns?.forEach(col => {
        const pk = col.primaryKey ? 'PK' : '';
        mermaid += `        ${col.type} ${col.name} ${pk}\n`;
      });
      mermaid += '    }\n';
    });

    // リレーション追加
    if (dataModel.data.relations) {
      dataModel.data.relations.forEach(rel => {
        const relType = rel.type === '1:1' ? '||--||' : '||--o{';
        mermaid += `    ${rel.fromTable} ${relType} ${rel.toTable} : "${rel.name}"\n`;
      });
    }

    mermaid += '```\n\n';
    return mermaid;
  };

  // 仕様書生成
  const generateFullSpecification = () => {
    setIsGenerating(true);

    let spec = '# システム仕様書\n\n';
    spec += `**生成日時:** ${new Date().toLocaleString('ja-JP')}\n\n`;

    // データモデルセクション
    if (ponData.dataModel && validatePonOutput(ponData.dataModel, PON_TYPES.DB).valid) {
      spec += '## データモデル\n\n';
      spec += generateERDiagram(ponData.dataModel);

      ponData.dataModel.data.tables.forEach(table => {
        spec += `### ${table.displayName}\n\n`;
        spec += `| カラム名 | 型 | NULL | 主キー |\n`;
        spec += `|----------|----|----|--------|\n`;
        table.columns?.forEach(col => {
          spec += `| ${col.displayName} | ${col.type} | ${col.nullable ? '○' : '×'} | ${col.primaryKey ? '○' : ''} |\n`;
        });
        spec += '\n';
      });
    }

    // UI画面セクション
    if (ponData.uiScreens && validatePonOutput(ponData.uiScreens, PON_TYPES.UI).valid) {
      spec += '## 画面仕様\n\n';
      ponData.uiScreens.data.screens.forEach(screen => {
        spec += `### ${screen.name}\n\n`;
        spec += `**種別:** ${screen.type}\n\n`;
        spec += `**データソース:** ${screen.dataSource}\n\n`;
      });
    }

    setMarkdown(spec);

    // Context保存
    const ponOutput = createPonOutput(PON_TYPES.MD, { markdown: spec });
    updatePonData('specification', ponOutput);

    setIsGenerating(false);
  };

  // 自動生成トリガー
  useEffect(() => {
    const hasDbData = validatePonOutput(ponData.dataModel, PON_TYPES.DB).valid;
    const hasUiData = validatePonOutput(ponData.uiScreens, PON_TYPES.UI).valid;

    if (hasDbData && hasUiData && !ponData.specification) {
      setTimeout(() => generateFullSpecification(), 500);
    }
  }, [ponData.dataModel, ponData.uiScreens]);

  return (
    <div className="h-full p-4" data-testid="md-pon-container">
      <Card title="MD PON! - 仕様書自動生成">
        <Button label="仕様書生成" onClick={generateFullSpecification} disabled={isGenerating} />

        <TabView>
          <TabPanel header="プレビュー">
            <ReactMarkdown remarkPlugins={[remarkGfm]}>{markdown}</ReactMarkdown>
          </TabPanel>
          <TabPanel header="Markdown">
            <textarea value={markdown} onChange={(e) => setMarkdown(e.target.value)} />
          </TabPanel>
        </TabView>
      </Card>
    </div>
  );
};

export default MDPon;
```

### フェーズ2: System PON!（コード生成）

**依存関係:**
```bash
npm install jszip file-saver
```

**LLMサービス:**

```javascript
// services/llmService.js

const PROMPT_TEMPLATES = {
  generateComponent: (spec) => `
あなたはReact開発者です。以下の仕様に基づいて、PrimeReactを使用したReactコンポーネントを生成してください。

## データモデル
${JSON.stringify(spec.dataModel, null, 2)}

## 画面仕様
${JSON.stringify(spec.screen, null, 2)}

コンポーネント名: ${spec.componentName}

コードのみを出力してください。
`,
};

// モックLLMレスポンス
const generateMockResponse = (prompt) => {
  const componentNameMatch = prompt.match(/コンポーネント名: (\w+)/);
  if (componentNameMatch) {
    const componentName = componentNameMatch[1];
    return `import React, { useState, useEffect } from 'react';
import { DataTable } from 'primereact/datatable';
import { Column } from 'primereact/column';
import { Button } from 'primereact/button';
import { Card } from 'primereact/card';

const ${componentName} = ({ dataSource }) => {
  const [data, setData] = useState([]);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    loadData();
  }, [dataSource]);

  const loadData = async () => {
    setLoading(true);
    try {
      const result = await fetch(\`/api/\${dataSource}\`);
      const json = await result.json();
      setData(json);
    } catch (error) {
      console.error('データ読み込みエラー:', error);
    } finally {
      setLoading(false);
    }
  };

  return (
    <Card title="${componentName}">
      <DataTable value={data} loading={loading} paginator rows={10}>
        <Column field="id" header="ID" sortable />
        <Column field="name" header="名前" sortable />
      </DataTable>
    </Card>
  );
};

export default ${componentName};
`;
  }
  return '// 生成されたコード';
};

export const generateComponent = async (spec) => {
  const prompt = PROMPT_TEMPLATES.generateComponent(spec);
  return new Promise((resolve) => {
    setTimeout(() => resolve(generateMockResponse(prompt)), 1000);
  });
};
```

**System PON!コンポーネント:**

```javascript
// system-pon/src/components/SystemPon.jsx
import JSZip from 'jszip';
import { saveAs } from 'file-saver';
import * as llmService from '../../../services/llmService';

const SystemPon = () => {
  const { ponData, updatePonData } = usePonData();
  const [generatedFiles, setGeneratedFiles] = useState([]);

  const handleGenerateCode = async () => {
    const fileSpecs = createFileSpecs(); // DB・UIデータから生成仕様作成
    const results = [];

    for (const spec of fileSpecs) {
      const code = await llmService.generateComponent(spec.spec);
      results.push({
        path: spec.path,
        content: code,
        type: spec.type,
        status: 'success',
      });
    }

    setGeneratedFiles(results);

    const ponOutput = createPonOutput(PON_TYPES.SYSTEM, {
      files: results,
      structure: {
        components: results.filter(r => r.type === 'component').map(r => r.path),
        services: results.filter(r => r.type === 'service').map(r => r.path),
      },
    });
    updatePonData('generatedCode', ponOutput);
  };

  const handleDownload = async () => {
    const zip = new JSZip();

    generatedFiles.forEach((file) => {
      if (file.status === 'success' && file.content) {
        zip.file(file.path, file.content);
      }
    });

    const readme = `# PON! 生成コード\n\n生成日時: ${new Date().toLocaleString('ja-JP')}`;
    zip.file('README.md', readme);

    const blob = await zip.generateAsync({ type: 'blob' });
    saveAs(blob, `pon-generated-code-${Date.now()}.zip`);
  };

  return (
    <div data-testid="system-pon-container">
      <Card title="System PON! - コード生成">
        <Button label="コード生成" onClick={handleGenerateCode} />
        <Button label="ZIPダウンロード" onClick={handleDownload} disabled={!generatedFiles.length} />

        <DataTable value={generatedFiles}>
          <Column field="path" header="ファイルパス" />
          <Column field="type" header="種別" />
          <Column field="status" header="ステータス" />
        </DataTable>
      </Card>
    </div>
  );
};
```

### フェーズ3: PON Flow Visualizer

```javascript
// components/PonFlowVisualizer.jsx
import { Timeline } from 'primereact/timeline';

const PonFlowVisualizer = () => {
  const { ponData } = usePonData();

  const ponFlow = [
    { name: 'DB PON!', dataKey: 'dataModel', ponType: PON_TYPES.DB, icon: 'pi pi-database' },
    { name: 'UI PON!', dataKey: 'uiScreens', ponType: PON_TYPES.UI, icon: 'pi pi-desktop' },
    { name: 'MD PON!', dataKey: 'specification', ponType: PON_TYPES.MD, icon: 'pi pi-file-edit' },
    { name: 'Test PON!', dataKey: 'testCases', ponType: PON_TYPES.TEST, icon: 'pi pi-check-circle' },
    { name: 'System PON!', dataKey: 'generatedCode', ponType: PON_TYPES.SYSTEM, icon: 'pi pi-code' },
  ];

  const events = ponFlow.map((pon) => {
    const data = ponData[pon.dataKey];
    const validation = validatePonOutput(data, pon.ponType);

    return {
      name: pon.name,
      status: validation.valid ? '成功' : '未実行',
      severity: validation.valid ? 'success' : 'secondary',
      icon: pon.icon,
      timestamp: data?.meta?.generatedAt || '-',
    };
  });

  const calculateProgress = () => {
    const completed = events.filter(e => e.severity === 'success').length;
    return Math.round((completed / events.length) * 100);
  };

  return (
    <Card title="PONフロー実行状態">
      <div>全体進捗: {calculateProgress()}%</div>
      <Timeline value={events} content={(item) => (
        <div>
          <h3>{item.name}</h3>
          <Tag value={item.status} severity={item.severity} />
        </div>
      )} />
    </Card>
  );
};
```

### フェーズ4: Auto PON Executor

```javascript
// components/AutoPonExecutor.jsx
import PonOrchestrator from '../services/ponOrchestrator';

const AutoPonExecutor = () => {
  const { clearPonData, updateExecutionStatus } = usePonData();
  const [requirement, setRequirement] = useState('');
  const [isExecuting, setIsExecuting] = useState(false);
  const [progress, setProgress] = useState(0);

  const handleAutoExecute = async () => {
    setIsExecuting(true);

    const orchestrator = new PonOrchestrator({
      stopOnError: true,
      delayBetweenPons: 1000,
    });

    const ponTriggers = {
      dbPon: async () => { /* DB PON!実行 */ },
      uiPon: async () => { /* UI PON!実行 */ },
      mdPon: async () => { /* MD PON!実行 */ },
      testPon: async () => { /* Test PON!実行 */ },
      systemPon: async () => { /* System PON!実行 */ },
    };

    const onProgress = (progressInfo) => {
      const percentage = (progressInfo.current / progressInfo.total) * 100;
      setProgress(percentage);
    };

    await orchestrator.executeAll(ponTriggers, updateExecutionStatus, onProgress);

    setIsExecuting(false);
  };

  return (
    <div data-testid="auto-pon-executor">
      <Card title="Auto PON Executor">
        <InputTextarea
          value={requirement}
          onChange={(e) => setRequirement(e.target.value)}
          placeholder="作りたいシステムの要件を入力"
        />
        <Button label="PON実行" onClick={handleAutoExecute} disabled={isExecuting} />
        <Button label="クリア" onClick={clearPonData} />

        {isExecuting && <ProgressBar value={progress} />}
      </Card>

      <PonFlowVisualizer />
    </div>
  );
};
```

### フェーズ5: PON Orchestrator

```javascript
// services/ponOrchestrator.js

export const PON_EXECUTION_ORDER = ['dbPon', 'uiPon', 'mdPon', 'testPon', 'systemPon'];

class PonOrchestrator {
  constructor(config = {}) {
    this.config = {
      stopOnError: true,
      delayBetweenPons: 500,
      ...config,
    };
  }

  async executeAll(ponTriggers, updateExecutionStatus, onProgress) {
    for (let i = 0; i < PON_EXECUTION_ORDER.length; i++) {
      const ponKey = PON_EXECUTION_ORDER[i];
      const trigger = ponTriggers[ponKey];

      updateExecutionStatus(ponKey, 'running');

      if (onProgress) {
        onProgress({
          current: i + 1,
          total: PON_EXECUTION_ORDER.length,
          ponKey,
          status: 'running',
        });
      }

      try {
        await trigger();
        updateExecutionStatus(ponKey, 'success');
      } catch (error) {
        updateExecutionStatus(ponKey, 'error', error.message);
        if (this.config.stopOnError) break;
      }

      await this.delay(this.config.delayBetweenPons);
    }
  }

  delay(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
  }
}

export default PonOrchestrator;
```

## E2Eテスト

```javascript
// e2e/complete-pon-flow.spec.js
import { test, expect } from '@playwright/test';

test.describe('Complete PON Flow', () => {
  test('should execute full PON flow', async ({ page }) => {
    await page.goto('http://localhost:3000');

    // Auto PONタブクリック
    await page.getByRole('tab', { name: 'Auto PON' }).click();

    // 要件入力
    await page.getByTestId('requirement-input').fill('ユーザー管理システム');

    // PON実行
    await page.getByTestId('execute-button').click();

    // 完了待機
    await page.waitForTimeout(10000);

    // PON Flow Visualizer確認
    await expect(page.getByTestId('pon-flow-visualizer')).toBeVisible();
  });

  test('should download ZIP file', async ({ page }) => {
    await page.goto('http://localhost:3000');
    await page.getByRole('tab', { name: 'System PON' }).click();

    await page.getByTestId('generate-code-button').click();
    await page.waitForTimeout(10000);

    const downloadButton = page.getByTestId('download-zip-button');
    await expect(downloadButton).toBeEnabled();
  });
});
```

## 統合チェックリスト

- [ ] PonDataContext作成・App.jsxでProvider配置
- [ ] PonDataTypes.jsで標準フォーマット定義
- [ ] MD PON!実装（Mermaid対応）
- [ ] System PON!実装（LLMサービス統合）
- [ ] PON Flow Visualizer実装
- [ ] Auto PON Executor実装
- [ ] PON Orchestrator実装
- [ ] 各PONでContext統合（usePonData使用）
- [ ] 自動データフロー実装（useEffect監視）
- [ ] Playwright E2Eテスト作成
- [ ] ビルド確認（npm run build）
- [ ] テスト実行（npx playwright test）

## 生成される成果物

### ZIPファイル構造

```
pon-generated-code-XXXXXX.zip
├── README.md
├── src/
│   ├── components/
│   │   ├── UserList.jsx
│   │   ├── ProductList.jsx
│   │   └── OrderList.jsx
│   ├── services/
│   │   ├── usersService.js
│   │   ├── productsService.js
│   │   └── ordersService.js
│   └── __tests__/
│       ├── UserList.test.jsx
│       └── ProductList.test.jsx
```

## 成功基準

✅ Auto PONタブで要件入力→PON実行→ZIP出力まで完了
✅ PON Flow Visualizerで全PONのステータス表示
✅ LocalStorageにPONデータ永続化
✅ Playwright E2Eテスト50%以上合格
✅ 生成されたZIPファイルに実行可能なReactコード含まれる

## 参考実装時間

- フェーズ1（MD PON）: 3-4時間
- フェーズ2（System PON + LLM）: 6-8時間
- フェーズ3（Flow Visualizer）: 4-5時間
- フェーズ4（Auto Executor）: 5-6時間
- フェーズ5（E2Eテスト）: 4-5時間

**合計: 22-28時間（約3-4日間）**
