---
name: issue-review-flow
description: Issueごとのブランチ/PRを受け入れる一連の作業（ブランチ切替 → AIコードレビュー＆自動修正 → Playwright動作確認＆自動修正 → サーバ起動＋手動確認チェックリスト → ユーザOK後に main へマージしPRクローズ）。「issue #N をレビューしてマージ」「PRを確認して取り込み」などで使う。/issue-review コマンドから呼ばれる。
version: 1.0.0
---

# Issue Review Flow

Issue ごとに切られたブランチ（例: `feature/issue-23-xxx`）と、その PR を受け入れるまでの定型フロー。

```
Phase 0 事前チェック
Phase 1 ブランチ切替
Phase 2 AIコードレビュー ──(CRITICAL/HIGH)──▶ 自動修正 → 再レビュー（最大3周）
Phase 3 Playwright確認  ──(失敗)──────────▶ 自動修正 → 再テスト（最大3周）
Phase 4 サーバ起動 + 手動確認チェックリスト ── ★ユーザの OK を必ず待つ
Phase 5 main へマージ（PR は自動クローズ）+ 後片付け
```

## 方針（ユーザ確定事項）

| 項目 | 決定 |
|------|------|
| 問題発見時 | **自動修正して続行**（ブランチ上で修正 → コミット → push → 再検証） |
| マージ方法 | `gh pr merge --merge --delete-branch`（マージコミット + リモートブランチ削除） |
| GitHub 操作 | `gh` CLI を使う（GitHub MCP は接続できない場合があるため） |
| マージ前 | **ユーザの手動確認 OK なしに絶対マージしない** |
| PR 本文の編集 | `gh pr edit` は旧 Projects 廃止の GraphQL エラーで失敗することがある → `gh api -X PATCH repos/<owner>/<repo>/pulls/<PR> -f body=...` を使う。本文に `Closes #N` を書くとマージ時にクローズされるので、意図しない番号に付けない |
| 呼び方 | ユーザへの説明・チェックリスト・質問は **Issue 番号**で話す（Issue と PR は通し番号を共有していてずれる。例: Issue #8 = PR #39）。PR 番号は gh コマンドに必要な箇所だけ「Issue #8（PR #39）」の形で添える |

自動修正は最大 3 周。3 周で解消しない／仕様判断が必要／修正が大規模（目安: 5 ファイル超 or 200 行超）になる場合は、そこで止めて状況を報告し指示を仰ぐ。

---

## 引数の解決

`$ARGUMENTS` に以下のいずれかが入る。空なら一覧を出して選んでもらう。

| 入力例 | 解決方法 |
|--------|---------|
| `23` / `#23` / `issue 23` | Issue 番号。`gh pr list --state open --json number,title,headRefName` から `headRefName` が `issue-23-` を含む、または本文に `#23` を含む PR を探す |
| `pr 51` / `PR#51` | PR 番号として直接使う |
| `feature/issue-23-xxx` | ブランチ名。`gh pr list --head <branch>` で PR を引く |
| （空） | `gh pr list --state open --limit 20` を表示し AskUserQuestion で選択 |

候補が複数／0 件なら推測で進めず確認する。PR が無いブランチの場合は「PR 無しでマージするか、PR を作るか」を確認する。

---

## worktree で実行する場合

`git worktree list` で対象ブランチがどこにチェックアウトされているかを最初に確認する。

| 状況 | 対応 |
|------|------|
| 今いるディレクトリが対象ブランチの worktree | `gh pr checkout` は使わない（既にチェックアウト済みでエラーになる）。`git pull --ff-only` だけ行う |
| 対象ブランチが別の worktree にある | そのパスで作業するか、ユーザに「その worktree で Claude を起動して `/issue-review` を実行」するよう案内する。本体側で同じブランチを checkout しない |

worktree の初回セットアップ（無ければ実行）:
- `node_modules`: `npm ci`。本体へのシンボリックリンクは Turbopack が「Next.js package not found」で落ちるので使わない
- `.env`: 本体の `.git/hooks/post-checkout` が `git worktree add` 時に自動作成する（本体の .env をコピーし、NEXTAUTH_URL をその worktree のポートに置換）。無ければ Claude は権限設定で作成・読み取りできないことがあるので、ユーザに `! sh ~/HJN/.claude/setup-worktrees.sh`（HJN の場合）か `! cp <本体>/.env .env` を案内する
- DB: `DATABASE_URL` が相対パス（例: `file:./dev.db`）なら worktree ごとに別 DB になる。`npx prisma migrate deploy` → `npx prisma db seed`
- vitest が `.env` を読まない構成なら、`DATABASE_URL="file:./dev.db" npx vitest run` のように環境変数を渡す

開発サーバのポート（worktree ごとに別ポートで並列実行する）:
- ポートは `node ../scripts/get-port.js`（worktree のルートで実行）で決める。PORT 環境変数 → `ports.json` → ディレクトリ名の `issue-<N>` から 3400+N → 既定 3262 の順。スクリプトが無ければユーザに配置を依頼する（作業ディレクトリ外は Claude から書けないことがある）
- `.env` の `NEXTAUTH_URL` がそのポートになっているか確認する（サーバ側の tRPC 呼び出しがこの URL を使うため、違うと別の worktree のサーバ・DB を見てしまう）。違えばユーザに `! sed 's/localhost:3262/localhost:<port>/' <本体>/.env > .env` を案内する
- サーバ起動: `npm run dev`（get-port.js があれば正しいポートで起動する）。無ければ `PORT=<port> npx next dev --turbopack`
- E2E: `PORT=<port> npx playwright test`。`playwright.config.*` がまだポート固定の版なら（PORT 対応がマージされる前のブランチ）、コミットしない上書き設定 `playwright.local.config.ts`（base を import して `use.baseURL` と `webServer.url` を差し替え）を作り、`.git/info/exclude` に追記して `npx playwright test -c playwright.local.config.ts` で実行する
- ポートが使用中なら `lsof -p <PID> -a -d cwd` で起動元を確認し、別ディレクトリのサーバなら別のポートを使う（勝手に止めない）
- チェックリストの URL は `http://localhost:<port>` にする
- Turbopack の開発サーバは、ブランチ切替・main の取り込みなどでファイルが一斉に変わると壊れることがある（Invalid hook call / module was instantiated because it was required ...）。E2E が想定外に落ちたらサーバを再起動して再実行する

## Phase 0: 事前チェック

並列で実行:

```bash
git status --porcelain          # 未コミット変更があれば停止して確認（勝手に stash しない）
gh auth status                  # 未ログインなら `! gh auth login` を案内
git fetch origin --prune
```

あわせてプロジェクト情報を把握する:
- `~/dotfiles/projects.yml` にプロジェクトが登録されていればポート・DB を読む
- 開発サーバのポート: `playwright.config.*` の `baseURL` / `webServer.url` → `package.json` の `dev` スクリプト → `.env` の `PORT` の順に探す
- テストコマンド: `package.json` の `scripts`（`lint`, `test`, `test:e2e`, `typecheck` 等）

## Phase 1: ブランチ切替

```bash
gh pr view <PR> --json number,title,body,headRefName,baseRefName,mergeable,mergeStateStatus,url   # closingIssuesReferences は gh のバージョンによって使えない
gh pr checkout <PR>
git pull --ff-only
gh issue view <N> --json title,body,state      # 受け入れ条件の確認用
git diff --stat origin/<base>...HEAD
```

- PR 本文の `Closes #N` / `## Test plan` と Issue 本文の受け入れ条件を抜き出し、以降の検証の「仕様」として使う
- **base より遅れていれば必ず取り込む**（`git rev-list --count HEAD..origin/<base>` が 1 以上）: `git merge origin/<base>` → 衝突を解消してコミット・push（自動修正方針）。`mergeable` が MERGEABLE / UNKNOWN でも取り込む（取り込まないと、main 側の変更が入っていない状態でレビュー・E2E をすることになり、テスト設定などの差で結果が当てにならない）。意図が判断できない衝突は止めて確認
- 取り込んだら `npm ci`（package-lock.json が変わった場合）、`npx prisma generate` と `npx prisma migrate deploy`（schema / migrations が変わった場合）を実行し、開発サーバを再起動する
- 差分にマイグレーション（`prisma/migrations/`, `drizzle/`, `database/migrations/` 等）が含まれる場合: DB 管理ルールに従い、可能ならバックアップ（`db-backup <project> <db>`）を提案してからマイグレーションを適用（例: `npx prisma migrate dev`）。シードが必要なら `db:seed` も

## Phase 2: AI コードレビュー + 自動修正

1. 対象は **ブランチ差分**: `git diff origin/<base>...HEAD`（`/code-review` コマンドは未コミット差分向けなので、そのチェック観点だけを流用する）
2. `code-reviewer` エージェントを起動。プロンプトに含めるもの:
   - base ブランチ名と差分取得コマンド
   - Issue / PR の受け入れ条件
   - `~/.claude/commands/code-review.md` の観点（Security=CRITICAL, Quality=HIGH, Best Practice=MEDIUM）
   - 「重大度・ファイル:行・問題・修正案」の形式で返すこと
3. 並行して静的チェックを実行（存在するものだけ）: `npm run lint`, `npx tsc --noEmit`, `npm test`
4. **CRITICAL / HIGH、lint/型/ユニットテストの失敗** → 自分で修正
   - 修正ごとにコミット: `fix: <内容> (#<N>)`（プロジェクトの既存コミット規約があればそちらに合わせる）
   - `git push`
   - 再レビュー（修正した観点に絞ってよい）。最大 3 周
5. MEDIUM / LOW は修正せず、Phase 4 のレポートに「指摘事項（未対応）」として載せる

## Phase 3: Playwright での実装確認 + 自動修正

### 3-1. サーバ確認・起動

```bash
lsof -nP -iTCP:<PORT> -sTCP:LISTEN     # 起動済みか
```

- 未起動 → `npm run dev` を **Bash の run_in_background** で起動し、`curl -s -o /dev/null -w "%{http_code}" http://localhost:<PORT>/` が 2xx/3xx を返すまで待つ（Monitor の until ループを使う。foreground sleep は使わない）
- 起動済みでも、別ブランチ由来のプロセス（`next start` などホットリロードしないもの）なら再起動する。`next dev` 等ホットリロードなら継続利用でよい
- 起動に失敗したらログを読んで原因を修正（自動修正方針）

### 3-2. 既存 E2E

- `test:e2e` / `playwright test` があれば実行。差分に関係する spec を優先し、時間がかかる場合は関連 spec のみ: `npx playwright test e2e/<関連>.spec.ts`
- 失敗したら原因を切り分ける:
  - ブランチの変更が原因 → アプリコードを修正
  - テストが仕様変更に追従していない → テストを修正（受け入れ条件に照らして正しい方に合わせる）
  - main でも落ちる既存の失敗 → 修正せず「既存の失敗」としてレポートに記載

### 3-3. 受け入れ条件の動作確認（Playwright MCP）

`mcp__playwright__*` で、Phase 1 で抜き出した受け入れ条件 / Test plan を 1 項目ずつ実際に操作して確認する。
- ログインが必要なら `e2e/helpers.*` やシードからテストアカウントを探して使う
- 各項目の結果（OK/NG）と、主要画面のスクリーンショットを scratchpad に保存
- `browser_console_messages` でコンソールエラーも確認
- NG → 修正 → コミット・push → 再確認（最大 3 周）
- 確認後はブラウザを閉じる（`browser_close`）

## Phase 4: 手動確認の準備（★ここで必ず止まる）

1. サーバが起動していることを再確認（止まっていれば 3-1 の手順で再起動）
2. 以下のチェックリストをチャットに出力する:

```markdown
## 手動確認チェックリスト — PR #<PR>: <タイトル>
URL: http://localhost:<PORT>   ブランチ: <branch>
テストアカウント: <role>: <email> / <password>（ローカル用シードのみ記載）

### AI 検証結果サマリ
- コードレビュー: CRITICAL x件 / HIGH x件 → 自動修正済み（コミット: <hash 一覧>）
- E2E: <passed>/<total>（既存の失敗: …）
- Playwright 受け入れ確認: <OK数>/<項目数>

### 手で確認してほしいこと
- [ ] <受け入れ条件 1>: <画面パス> で <操作> → <期待結果>
- [ ] <受け入れ条件 2>: …
- [ ] AI が自動修正した箇所: <修正内容> の挙動
- [ ] 見た目・文言・レイアウト（自動では判定しにくいもの）
- [ ] 権限違い（例: 一般ユーザでは見えない／操作できない）
- [ ] 異常系（空入力・不正値・通信エラー時の表示）

### 未対応の指摘（MEDIUM/LOW）
- <ファイル:行> <内容>
```

   - 項目は Issue / PR の受け入れ条件から具体的に作る（汎用の項目を並べるだけにしない）
   - Playwright で NG のまま残った項目や自動化できなかった項目は先頭に置き、⚠️ を付ける
3. AskUserQuestion で確認する:
   - 「確認OK → main にマージ」
   - 「修正が必要」→ 内容を聞いて修正し、Phase 2 から再実行
   - 「中断（マージしない）」→ 状態を報告して終了

ユーザの明示的な OK が無い限り Phase 5 に進まない。

- 「マージして」「確認OK」など**マージそのものへの明示的な指示**だけを OK とみなす
- 方針の決定（例:「このUIを採用」「main書き換えで」）や不具合報告への回答は OK ではない。方針が決まったら、必ず改めて「マージしてよいか」「未対応の指摘を Issue に残すか」を確認する
- 未対応の指摘（MEDIUM/LOW）は、マージ前に「Issue にコメントで残す／別 Issue にする／放置」のどれにするか確認する（マージで Issue が自動クローズされるため）

## Phase 5: マージと後片付け

```bash
git status --porcelain                         # 未 push の修正が無いこと
git push                                       # 念のため
gh pr checks <PR>                              # CI があれば確認。失敗中ならマージせず報告
gh pr merge <PR> --merge --delete-branch       # PR はマージで自動クローズ
git checkout <base> && git pull --ff-only
git branch -d <branch> 2>/dev/null || true     # ローカルブランチ（--delete-branch で消えていなければ）
gh pr view <PR> --json state,mergedAt
gh issue view <N> --json state
```

- `gh pr merge` が失敗（保護ルール・レビュー必須・コンフリクト等）したら、勝手に `--admin` を付けずエラー内容を報告して指示を仰ぐ
- PR 本文に `Closes #N` が無く Issue が OPEN のままなら、Issue をクローズするか確認する
- 開発サーバは main 上で動き続ける。止めるかどうかは報告時に一言添える

### 最終報告

```markdown
✅ PR #<PR> をマージしました（<mergeコミット hash>）
- Issue #<N>: CLOSED / OPEN
- 自動修正コミット: x 件
- 未対応の指摘: x 件（必要なら別 Issue 化を提案）
```

---

## 禁止事項

- ユーザの手動確認 OK 前のマージ
- `--admin` / `--force` によるマージ・push、保護ルールの迂回
- 未コミット変更の無断 stash / 破棄
- テストを通すためだけのテスト削除・skip 化
- 本番 DB への接続・マイグレーション
