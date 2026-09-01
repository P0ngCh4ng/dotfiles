# Automation Scripts

このディレクトリには、dotfiles管理と開発環境のメンテナンスを自動化するスクリプトが含まれています。

## Scripts Overview

| Script | Purpose | Usage Context |
|--------|---------|---------------|
| `update-cage-config` | Cage設定自動生成 | プロジェクト追加時 |
| `fix-project-quarantine` | macOS隔離属性削除 | 権限エラー時 |
| `emacs-auto-fix` | Emacs設定自動修正 | 設定エラー時 |
| `generate-project-dashboard` | 稼働中Webプロジェクトの一覧ダッシュボード（`pj-dashboard`が呼ぶ） | いつでも |
| `install-dashboard-service` | ダッシュボードをlaunchd常駐サービス化 | 初回セットアップ時（**cageの外で実行**） |

---

## update-cage-config

### 概要
`projects.yml` から自動的にCageサンドボックス設定 (`.config/cage/presets.yaml`) を生成します。

### 使用方法

```bash
# 直接実行
~/dotfiles/bin/update-cage-config

# または Makefileから
cd ~/dotfiles
make update-cage

# deployで自動実行
make deploy
```

### 動作

1. `projects.yml` からプロジェクトパスを抽出（Python + YAML）
2. `.config/cage/presets.yaml.template` のプレースホルダー `{{PROJECTS}}` を置換
3. `.config/cage/presets.yaml` を生成

### 生成される設定

```yaml
presets:
  claude-code:
    allow:
      - "/Users/pongchang/.claude"  # eval-symlinks: true
      - "/Users/pongchang/.serena"
      - "/Users/pongchang/.npm"
      # ... グローバルディレクトリ
      # プロジェクトディレクトリ（自動生成）
      - "/Users/pongchang/dotfiles"
      - "/Users/pongchang/pon"
      - "/Users/pongchang/SOKKO"
      # ...
    allow-keychain: true
```

### 重要事項

- **`.config/cage/presets.yaml` は自動生成です。直接編集しないでください。**
- テンプレート (`.config/cage/presets.yaml.template`) を編集して、グローバル設定を変更します
- `projects.yml` を編集して、プロジェクトパスを追加/削除します

### エラー処理

| エラー | 原因 | 解決方法 |
|--------|------|----------|
| `projects.yml not found` | ファイルが存在しない | `cp projects.yml.example projects.yml` |
| `No projects found` | YAMLが空または不正 | `projects.yml` の構文を確認 |
| Python エラー | YAML解析失敗 | `python3 -c "import yaml"` でyamlモジュールを確認 |

### 検証

```bash
# Dry-runで設定を検証
cage -dry-run -config ~/.config/cage/presets.yaml -preset claude-code echo test

# 実際に実行
cd ~/some-project
cage -config ~/.config/cage/presets.yaml -preset claude-code claude
```

---

## fix-project-quarantine

### 概要
macOSの隔離属性 (`com.apple.quarantine`) を削除し、プロジェクトディレクトリへの書き込み権限を復元します。

### 使用方法

```bash
# プロジェクトの隔離属性を削除
~/dotfiles/bin/fix-project-quarantine ~/AutomationVideo

# または
cd ~/dotfiles
./bin/fix-project-quarantine ~/projects/myapp
```

### 動作

1. `IN_CAGE` 環境変数をチェック（cage内では実行不可）
2. 指定されたディレクトリの隔離属性を検出
3. 隔離属性を再帰的に削除 (`xattr -r -d`)
4. 書き込み権限をテスト

### 出力例

```bash
$ fix-project-quarantine ~/AutomationVideo
🔍 Checking quarantine attribute on: /Users/pongchang/AutomationVideo
⚠️  Quarantine attribute found, removing...
✅ Quarantine attribute removed
✅ Write permission OK

✅ Project is ready: /Users/pongchang/AutomationVideo
```

### 使用場面

#### Cage + EPERMエラー
```
Error: EPERM: operation not permitted, open '/path/to/file'
```

**原因**: macOSがダウンロードまたは外部ソースからのディレクトリに隔離属性を付与

**解決**:
1. ターミナルから（Emacsの外で）実行
2. `fix-project-quarantine ~/problem-project`
3. Emacsを再起動

#### ファイル作成/編集エラー

Git操作やファイル作成時に権限エラーが発生する場合にも有効です。

### 制限事項

- **cage内では実行できません**（`IN_CAGE` 環境変数をチェック）
- 通常のターミナルから実行してください
- Sudo権限は不要（自分のホームディレクトリ内のみ）

### トラブルシューティング

| 問題 | 解決方法 |
|------|----------|
| "must be run outside of cage" | 通常のターミナル（iTerm2/Terminal.app）から実行 |
| "Write permission denied" | `chmod -R u+w ~/project-path` を実行 |
| "No such xattr" | 正常（隔離属性が存在しなかった） |

---

## emacs-auto-fix

### 概要
Emacs設定ファイルの一般的なエラーを自動修正します。JSON入力/出力でスクリプト連携に最適化。

### 使用方法

```bash
# JSON入力でファイルを修正
echo '{"file":"/path/to/init.el"}' | ~/dotfiles/bin/emacs-auto-fix

# 結果（JSON出力）
{
  "success": true,
  "file": "/path/to/init.el",
  "backup": "/path/to/init.el.autofix.20260327_120000",
  "fixes": [
    "Added 2 missing closing parentheses",
    "flet -> cl-flet"
  ],
  "fixCount": 2
}
```

### 自動修正パターン

#### 1. 括弧の不均衡
```elisp
# 修正前
(defun foo ()
  (message "Hello"
# 修正後
(defun foo ()
  (message "Hello"))
```

#### 2. 廃止された関数の置換

| 旧関数 | 新関数 |
|--------|--------|
| `flet` | `cl-flet` |
| `labels` | `cl-labels` |
| `lexical-let` | `let` |
| `string-to-int` | `string-to-number` |

#### 3. 不足しているrequire文の追加

検出された関数に基づいて、必要な `(require 'package)` を自動追加:

- `use-package` → `(require 'use-package)`
- `cl-loop`, `cl-defun` → `(require 'cl-lib)`
- `package-install` → `(require 'package)`

#### 4. ホワイトスペースの修正

- 行末の空白を削除
- ファイル末尾に改行を追加

### バックアップ

自動的にバックアップが作成されます:
```
/path/to/file.el.autofix.20260327_120000
```

修正が適用されなかった場合、バックアップは削除されます。

### 統合例（emacs-verifier agent）

このスクリプトは `emacs-verifier` エージェントで使用されます:

```javascript
// エージェントがエラーを検出
const errors = detectErrors(file);

// 自動修正を試行
const result = execSync(
  `echo '${JSON.stringify({file, errors})}' | ~/dotfiles/bin/emacs-auto-fix`
);

// 結果を解析
const fixResult = JSON.parse(result);
if (fixResult.success && fixResult.fixCount > 0) {
  console.log(`✅ Applied ${fixResult.fixCount} fixes`);
}
```

### 制限事項

- **保守的な修正**: 明らかなケースのみ修正（破壊的変更を避ける）
- **手動確認推奨**: 複雑なエラーは人間の判断が必要
- **バックアップ必須**: 必ずバックアップを確認してから使用

### エラーコード

| ステータス | 説明 |
|------------|------|
| `success: true, fixCount > 0` | 修正を適用 |
| `success: true, fixCount: 0` | 修正不要 |
| `success: false` | エラー（ファイルが見つからない等） |

---

## generate-project-dashboard / install-dashboard-service

### 概要

`generate-project-dashboard` は `projects.yml` を元に、PC上で今動いているWebプロジェクトを一覧できるローカルダッシュボードを生成・配信するPythonスクリプト。実行中ポートの判定は `lsof`（`check-ports`/`port-scan` と同じ実測方式）、`projects.yml` 未登録のプロセスも`cwd`/コマンドラインから識別してカード表示し、その場で「既存プロジェクトに追加」「新規登録」「停止」ができる。

**常駐指定プロジェクト（always_on）**: `projects.yml` のプロジェクトに `always_on: true` を付けると、「常に動かしておくべきプロジェクト」として扱われる。ダッシュボードは🔁常駐バッジを付け、そのプロジェクトのポートがどれもLISTENしていなければ**上部に赤バナー警告＋カードを赤ハイライト**する。さらに `start_command: "..."` を書いておくと、停止中のカードに「▶ 起動」ボタンが出て、ワンクリックでそのコマンドをプロジェクトの `path` ディレクトリで起動できる（`/api/start`。コマンド本体はブラウザには渡さず、サーバー側が `projects.yml` から名前で引く）。

```yaml
  myapp:
    path: ~/myapp
    ports: [3000]
    always_on: true
    start_command: "npm run dev"   # dashboard server の環境を継承するため、
                                   # node/uv/docker等はフルパス or `source`推奨
```

> 注: launchd常駐サービス経由で配信している場合、`start_command` は最小限の環境（PATHが薄い）で実行される。`pj-dashboard` をシェルから起動した場合はそのシェルの環境を継承する。

`install-dashboard-service` は、このダッシュボードサーバーを**ログイン時に自動起動する常駐サービス（launchd LaunchAgent）として登録**するための一回限りのセットアップスクリプト。

### 手順書（初回セットアップ）

**⚠️ 重要: このコマンドは cage の外（通常のターミナル / cage を経由しないシェル）で実行してください。**

`launchctl` はXPC経由でlaunchdと通信するため、cageサンドボックス内（`IN_CAGE=1`環境、つまりEmacsの`C-c c`から起動したClaude Codeセッションや`cage`ラッパー経由のシェル）からは `operation not permitted` で失敗し、サービスを有効化できません。`ps`が同じ理由でcage内では使えないのと同じ制約です。

**手順:**

1. cageを経由しない通常のターミナル（Terminal.app / iTerm2など）を開く
2. 以下を実行:
   ```bash
   cd ~/dotfiles
   make dashboard-service
   ```
3. 成功すると、以下のような出力が出る:
   ```
   ✅ Wrote /Users/pongchang/Library/LaunchAgents/com.pongchang.pj-dashboard.plist
   ✅ Dashboard is running at http://localhost:9797/ (auto-starts at login from now on)

   To disable autostart later:
     launchctl unload ~/Library/LaunchAgents/com.pongchang.pj-dashboard.plist && rm ...
   ```
4. ブラウザで `http://localhost:9797/` を開いて確認、または以後は `pj-dashboard` （zsh関数）でいつでも開ける

### 動作（`install-dashboard-service` の中身）

1. `python3` の絶対パスを検出（`command -v python3`）
2. `~/Library/LaunchAgents/com.pongchang.pj-dashboard.plist` を生成
   - `ProgramArguments`: `<python3> <dotfiles>/bin/generate-project-dashboard --serve --port 9797`
   - `RunAtLoad: true`（ログイン時に自動起動）
   - `KeepAlive: true`（落ちたら自動再起動）
   - ログ出力先: `~/dotfiles/.dashboard/launchd.log`
3. `launchctl unload`（既存分の後始末、失敗しても無視） → `launchctl load -w` で有効化
4. `curl` で `http://localhost:9797/api/status` に疎通確認

### 検証済み事項

- 生成されるplistのXML構文は `plutil -lint` でOKを確認済み
- `ProgramArguments` に埋め込む `python3` / スクリプトの絶対パスは実際の環境値で確認済み
- `lsof` (`/usr/sbin/lsof`)・`ps` (`/bin/ps`)・`kill` (`/bin/kill`) は launchd のデフォルトPATH（`/usr/bin:/bin:/usr/sbin:/sbin`）内にあり、追加のPATH設定なしで動作する
- **`launchctl load` の実行自体は cage サンドボックス内から検証不可**（上記の制約により）。cageの外で実行した際に問題があれば、`~/dotfiles/.dashboard/launchd.log` を確認してください

### 無効化・やり直し

```bash
launchctl unload ~/Library/LaunchAgents/com.pongchang.pj-dashboard.plist
rm ~/Library/LaunchAgents/com.pongchang.pj-dashboard.plist
```

設定を変更して再セットアップしたい場合は、`make dashboard-service` を再実行すれば `unload` → 再生成 → `load` を自動でやり直す。

### トラブルシューティング

| 問題 | 解決方法 |
|------|----------|
| `operation not permitted`（launchctl） | cageの外（通常のターミナル）で実行しているか確認 |
| サービス有効化後もポートに接続できない | `cat ~/dotfiles/.dashboard/launchd.log` でエラーを確認 |
| ポート9797が別プロセスに使われている | `lsof -iTCP:9797 -sTCP:LISTEN` で確認し、該当プロセスを停止するか `install-dashboard-service` 内の `PORT` を変更 |
| launchdサービスの状態を見たい | `launchctl list \| grep pj-dashboard` |

---

## 開発ワークフロー

### 新しいプロジェクトを追加

```bash
# 1. projects.ymlを編集
vim ~/dotfiles/projects.yml

# 2. Cage設定を更新
make update-cage

# または
~/dotfiles/bin/update-cage-config

# 3. 検証
cage -dry-run -config ~/.config/cage/presets.yaml -preset claude-code echo "test"
```

### macOSでCage + EPERM問題を解決

```bash
# 1. 通常のターミナルから実行
~/dotfiles/bin/fix-project-quarantine ~/problem-project

# 2. Emacsを再起動

# 3. Cage経由でClaude Codeを起動
# (C-c c から)
```

### Emacs設定の検証と修正

```bash
# 1. バッチモードで構文チェック
emacs --batch --eval '(check-parens)' -l ~/.emacs.d/init.el

# 2. エラーが見つかった場合、自動修正を試行
echo '{"file":"~/.emacs.d/init.el"}' | ~/dotfiles/bin/emacs-auto-fix

# 3. 再度検証
emacs --batch -l ~/.emacs.d/init.el

# または emacs-verifier エージェントを使用
# @agent-emacs-verifier
```

---

## トラブルシューティング

### Cageが正しく動作しない

```bash
# 設定を再生成
make update-cage

# Dry-runで確認
cage -dry-run -config ~/.config/cage/presets.yaml -preset claude-code pwd

# 詳細なデバッグ
cage -config ~/.config/cage/presets.yaml -preset claude-code -v echo test
```

### プロジェクトパスが認識されない

```bash
# 1. projects.ymlを確認
cat ~/dotfiles/projects.yml

# 2. YAMLの構文を検証
python3 -c "import yaml; yaml.safe_load(open('~/dotfiles/projects.yml'))"

# 3. 再生成
make update-cage

# 4. 生成されたファイルを確認
cat ~/.config/cage/presets.yaml
```

### Emacs自動修正が失敗する

```bash
# 手動でバックアップを作成
cp ~/.emacs.d/init.el ~/.emacs.d/init.el.backup

# 詳細な出力で実行
echo '{"file":"~/.emacs.d/init.el"}' | ~/dotfiles/bin/emacs-auto-fix | jq .

# バックアップから復元
cp ~/.emacs.d/init.el.backup ~/.emacs.d/init.el
```

---

## 関連ドキュメント

- **[README.md](../README.md)** - Dotfilesリポジトリ概要
- **[CLAUDE.md](../CLAUDE.md)** - Claude Code用プロジェクト情報
- **[PROJECT_MANAGEMENT.md](../PROJECT_MANAGEMENT.md)** - プロジェクト管理システム
- **[Makefile](../Makefile)** - 主要管理インターフェース
- **~/.claude/rules/emacs-environment.md** - Emacs環境の詳細

---

## 今後の拡張

- [ ] `update-cage-config`: 環境変数のサポート
- [ ] `fix-project-quarantine`: バッチ処理（複数プロジェクト）
- [ ] `emacs-auto-fix`: より多くの廃止関数パターン
- [ ] 新スクリプト: `check-dependencies` - 不足しているツールを検出

---

**最終更新**: 2026-03-27
**メンテナ**: Claude Code + User
