# PON接続 実装例

## 1. Context実装の完全な例

### contexts/PonDataContext.jsx

```javascript
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
  dataModel: null,
  uiScreens: null,
  specification: null,
  testCode: null,
  systemCode: null
};

export const PonDataProvider = ({ children }) => {
  const [ponData, setPonData] = useState(() => {
    // LocalStorageから復元
    const saved = localStorage.getItem('pon-data');
    if (saved) {
      try {
        return JSON.parse(saved);
      } catch (error) {
        console.error('PONデータの復元に失敗:', error);
        return initialState;
      }
    }
    return initialState;
  });

  // 自動保存
  useEffect(() => {
    localStorage.setItem('pon-data', JSON.stringify(ponData));
  }, [ponData]);

  // データクリア関数
  const clearPonData = () => {
    setPonData(initialState);
    localStorage.removeItem('pon-data');
  };

  // 特定のPONデータのみ更新
  const updatePonData = (key, value) => {
    setPonData(prev => ({ ...prev, [key]: value }));
  };

  return (
    <PonDataContext.Provider
      value={{
        ponData,
        setPonData,
        updatePonData,
        clearPonData
      }}
    >
      {children}
    </PonDataContext.Provider>
  );
};
```

## 2. データ型定義の完全な例

### types/PonDataTypes.js

```javascript
/**
 * 現在のプロジェクトIDを取得
 */
const getCurrentProjectId = () => {
  const currentProject = localStorage.getItem('manual_pon_current_project');
  return currentProject || 'default_project';
};

/**
 * PON共通出力フォーマット作成
 */
export const createPonOutput = (ponType, data, error = null) => {
  const output = {
    meta: {
      ponType,
      version: '1.0.0',
      generatedAt: new Date().toISOString(),
      projectId: getCurrentProjectId(),
      success: !error
    },
    data
  };

  if (error) {
    output.meta.error = error;
  }

  return output;
};

/**
 * データ型のバリデーション
 */
export const validatePonOutput = (output, expectedType) => {
  if (!output || !output.meta) {
    return { valid: false, error: 'Invalid PON output format' };
  }

  if (output.meta.ponType !== expectedType) {
    return {
      valid: false,
      error: `Expected ${expectedType}, got ${output.meta.ponType}`
    };
  }

  if (!output.meta.success) {
    return {
      valid: false,
      error: output.meta.error || 'Unknown error'
    };
  }

  return { valid: true };
};

/**
 * DB PON!データ型
 */
export const DBPonDataType = {
  tables: [
    {
      id: 'string',
      name: 'string',
      displayName: 'string',
      description: 'string',
      columns: [
        {
          id: 'string',
          name: 'string',
          displayName: 'string',
          type: 'string',
          nullable: 'boolean',
          primaryKey: 'boolean',
          unique: 'boolean',
          defaultValue: 'any'
        }
      ],
      indexes: [
        {
          name: 'string',
          columns: ['string'],
          unique: 'boolean'
        }
      ]
    }
  ],
  relations: [
    {
      id: 'string',
      name: 'string',
      fromTable: 'string',
      toTable: 'string',
      type: '1:1 | 1:N | N:N',
      fromColumn: 'string',
      toColumn: 'string'
    }
  ]
};

/**
 * UI PON!データ型
 */
export const UIPonDataType = {
  screens: [
    {
      id: 'string',
      name: 'string',
      type: 'list | detail | form',
      description: 'string',
      dataSource: 'string',
      reactCode: 'string',
      components: [
        {
          id: 'string',
          type: 'string',
          props: 'object'
        }
      ]
    }
  ],
  navigation: [
    {
      from: 'string',
      to: 'string',
      trigger: 'string'
    }
  ]
};

/**
 * MD PON!データ型
 */
export const MDPonDataType = {
  markdown: 'string',
  sections: {
    overview: 'string',
    dataModel: 'string',
    screens: 'string',
    navigation: 'string',
    apiSpec: 'string'
  }
};

/**
 * Test PON!データ型
 */
export const TestPonDataType = {
  unitTests: 'string',
  integrationTests: 'string',
  testCases: [
    {
      id: 'string',
      type: 'unit | integration',
      target: 'string',
      description: 'string',
      status: 'pending | passed | failed'
    }
  ]
};

/**
 * System PON!データ型
 */
export const SystemPonDataType = {
  files: [
    {
      path: 'string',
      content: 'string',
      type: 'component | service | schema | config | test'
    }
  ],
  structure: {
    frontend: ['string'],
    backend: ['string'],
    tests: ['string'],
    config: ['string']
  }
};
```

## 3. 各PONの実装パターン

### DB PON!

```javascript
import { usePonData } from '../../contexts/PonDataContext';
import { createPonOutput } from '../../types/PonDataTypes';

const DBPon = () => {
  const { updatePonData } = usePonData();
  const [processing, setProcessing] = useState(false);

  const handleGenerate = async (inputText) => {
    setProcessing(true);

    try {
      // LLMでデータモデル生成
      const result = await generateDataModelWithLLM(inputText);

      // PON形式でラップ
      const output = createPonOutput('DB_PON', {
        tables: result.tables,
        relations: result.relations
      });

      // Contextに保存（自動的に次のPONへ伝播）
      updatePonData('dataModel', output);

    } catch (error) {
      // エラー時
      const errorOutput = createPonOutput(
        'DB_PON',
        { tables: [], relations: [] },
        error.message
      );
      updatePonData('dataModel', errorOutput);
    } finally {
      setProcessing(false);
    }
  };

  return (
    <div>
      <InputTextarea onChange={(e) => setInput(e.target.value)} />
      <Button label="生成" onClick={() => handleGenerate(input)} />
    </div>
  );
};
```

### UI PON!

```javascript
import { usePonData } from '../../contexts/PonDataContext';
import { createPonOutput, validatePonOutput } from '../../types/PonDataTypes';

const UIPon = () => {
  const { ponData, updatePonData } = usePonData();
  const [autoGenerated, setAutoGenerated] = useState(false);

  // 自動生成トリガー
  useEffect(() => {
    const validation = validatePonOutput(ponData.dataModel, 'DB_PON');

    // DB PON!のデータが有効 かつ 未生成
    if (validation.valid && !autoGenerated && !ponData.uiScreens) {
      console.log('🎨 UI PON! 自動生成開始');
      generateScreensAutomatically();
    }
  }, [ponData.dataModel, autoGenerated]);

  const generateScreensAutomatically = async () => {
    try {
      const screens = await generateScreensFromDataModel(ponData.dataModel.data);

      const output = createPonOutput('UI_PON', {
        screens,
        navigation: generateNavigation(screens)
      });

      updatePonData('uiScreens', output);
      setAutoGenerated(true);

    } catch (error) {
      const errorOutput = createPonOutput(
        'UI_PON',
        { screens: [], navigation: [] },
        error.message
      );
      updatePonData('uiScreens', errorOutput);
    }
  };

  // エラーハンドリング
  if (!ponData.dataModel) {
    return (
      <Message
        severity="warn"
        text="DB PON!でデータモデルを生成してください"
      />
    );
  }

  const validation = validatePonOutput(ponData.dataModel, 'DB_PON');
  if (!validation.valid) {
    return (
      <Message
        severity="error"
        text={`DB PON!エラー: ${validation.error}`}
      />
    );
  }

  return <div>UI PON!の実装...</div>;
};
```

### MD PON!

```javascript
const MDPon = () => {
  const { ponData, updatePonData } = usePonData();
  const [autoGenerated, setAutoGenerated] = useState(false);

  useEffect(() => {
    // DB PON! と UI PON! の両方が完了していれば自動生成
    const dbValid = validatePonOutput(ponData.dataModel, 'DB_PON').valid;
    const uiValid = validatePonOutput(ponData.uiScreens, 'UI_PON').valid;

    if (dbValid && uiValid && !autoGenerated && !ponData.specification) {
      console.log('📝 MD PON! 自動生成開始');
      generateSpecificationAutomatically();
    }
  }, [ponData.dataModel, ponData.uiScreens, autoGenerated]);

  const generateSpecificationAutomatically = async () => {
    try {
      const markdown = await generateMarkdownSpec(
        ponData.dataModel.data,
        ponData.uiScreens.data
      );

      const output = createPonOutput('MD_PON', {
        markdown,
        sections: parseMarkdownSections(markdown)
      });

      updatePonData('specification', output);
      setAutoGenerated(true);

    } catch (error) {
      const errorOutput = createPonOutput(
        'MD_PON',
        { markdown: '', sections: {} },
        error.message
      );
      updatePonData('specification', errorOutput);
    }
  };

  // 前提PONのチェック
  if (!ponData.dataModel || !ponData.uiScreens) {
    return (
      <Message
        severity="warn"
        text="DB PON!とUI PON!を完了してください"
      />
    );
  }

  return <div>MD PON!の実装...</div>;
};
```

## 4. App.jsxでの統合

```javascript
import { PonDataProvider } from './contexts/PonDataContext';
import DBPon from './db-pon/src/components/DBPon';
import UIPon from './ui-pon/src/components/UIPon';
import MDPon from './md-pon/src/components/MDPon';
import TestPon from './test-pon/src/components/SmartTestPon';
import SystemPon from './system-pon/src/components/SystemPon';

const App = () => {
  return (
    <PonDataProvider>
      <div className="h-screen flex flex-column">
        <TabView>
          <TabPanel header="DB PON!">
            <DBPon />
          </TabPanel>

          <TabPanel header="UI PON!">
            <UIPon />
          </TabPanel>

          <TabPanel header="MD PON!">
            <MDPon />
          </TabPanel>

          <TabPanel header="Test PON!">
            <TestPon />
          </TabPanel>

          <TabPanel header="System PON!">
            <SystemPon />
          </TabPanel>
        </TabView>
      </div>
    </PonDataProvider>
  );
};

export default App;
```

## 5. デバッグツール

```javascript
// components/PonDataDebugger.jsx
import { usePonData } from '../contexts/PonDataContext';

const PonDataDebugger = () => {
  const { ponData, clearPonData } = usePonData();

  return (
    <Dialog header="PONデータデバッガー" visible={true}>
      <pre>{JSON.stringify(ponData, null, 2)}</pre>
      <Button label="全データクリア" onClick={clearPonData} severity="danger" />
    </Dialog>
  );
};
```

## 6. 通知システム（オプション）

```javascript
// hooks/usePonNotifications.js
export const usePonNotifications = () => {
  const { ponData } = usePonData();
  const toast = useRef(null);

  useEffect(() => {
    if (ponData.dataModel?.meta.success) {
      toast.current?.show({
        severity: 'success',
        summary: 'DB PON!完了',
        detail: 'UI PON!で画面生成中...'
      });
    }
  }, [ponData.dataModel]);

  useEffect(() => {
    if (ponData.uiScreens?.meta.success) {
      toast.current?.show({
        severity: 'success',
        summary: 'UI PON!完了',
        detail: 'MD PON!で仕様書生成中...'
      });
    }
  }, [ponData.uiScreens]);

  return toast;
};
```
