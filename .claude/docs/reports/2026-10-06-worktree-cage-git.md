# 調査レポート: Emacs から起動した worktree セッションで git が使えない

日付: 2026-10-06
対象: `claude-code-projects.el` の worktree 付きセッション（cage 有効）

## 症状

`C-c C-p` → Create new session → worktree を作成 → その中の Claude Code で
`git add` / `git commit` / `git stash` / `git checkout -b` などの書き込み系操作が失敗する。
`git status` / `git log` / `git diff` などの読み取り系は動く（index のリフレッシュ失敗は黙って無視されるため）。

## 原因

### 1. worktree の git データは worktree の外にある（本質的な原因）

worktree の `.git` はディレクトリではなく、本体リポジトリを指すファイル:

```
~/HJN-worktrees/feature-issue-13-comprehension-test/.git
  → gitdir: /Users/pongchang/HJN/.git/worktrees/feature-issue-13-comprehension-test
```

| git が書き込む場所 | 実体 |
|---|---|
| index / HEAD / index.lock | `~/HJN/.git/worktrees/<name>/` |
| objects（コミット・blob） | `~/HJN/.git/objects/` |
| refs（ブランチ） | `~/HJN/.git/refs/` |

cage は「起動ディレクトリ（`.`）＋許可リスト」以外への書き込みを拒否する。
Emacs が worktree 作成時に許可リストへ追加するのは **worktree ディレクトリだけ**なので、
本体の `.git` は書き込み不可のまま。

### 2. HJN が cage の許可リストに入っていなかった（今回それが表面化した理由）

dotfiles 以外のプロジェクトは `bin/update-cage-config` が `projects.yml` から本体パスを
許可リストに入れるため、本体 `.git` も結果として書ける。pon / SOKKO などの worktree で
問題が出なかったのはこのため。

ところが `hjn`（`~/HJN`）は `projects.yml` に登録された（14:08）あと、cage 設定が再生成されていなかった。
`projects.yml` を変更しても cage 設定を自動で同期する仕組みがなく、
ダッシュボードの「登録」ボタン（`register_project`）も `projects.yml` に追記するだけだった。

### 再現（調査時の実測）

同じ worktree から旧コマンド（`-allow-git` なし）で書き込みを試した結果:

| 書き込み先 | 旧コマンド | `-allow-git` 付き |
|---|---|---|
| `~/HJN/.git/worktrees/<name>/` | DENY | OK |
| `~/HJN/.git/objects/` | DENY | OK |
| `~/HJN/.git/refs/heads/` | DENY | OK |
| `~/HJN/`（本体の作業ツリー） | DENY | DENY（cage 設定再生成後は OK） |
| `~/.gitconfig` | DENY | DENY |
| `~/.ssh/` | DENY | DENY |
| `~/Library/Preferences/` | DENY | DENY |

## 同じ仕組みで起きうる他の「できないこと」

いずれも「cage の許可リスト外への書き込み」が原因。

| できないこと | 書き込み先 | 状態 |
|---|---|---|
| worktree で git の書き込み操作 | 本体 `.git` | **修正済み**（`-allow-git`） |
| worktree から本体リポジトリのファイルを編集 | `~/HJN/` など | **修正済み**（起動時に毎回 cage 設定を同期） |
| 新規登録プロジェクトで別セッションから書き込み | 新プロジェクトのパス | **修正済み**（同上＋ダッシュボード登録時に同期） |
| `git config --global ...` | `~/.gitconfig` | 未対応（意図的。必要なら `claude-raw` か Emacs 外で） |
| SSH remote への初回 push/fetch（known_hosts 追記） | `~/.ssh/known_hosts` | 未対応。現状のリモートは https＋keychain（`allow-keychain: true`）なので影響なし |
| `conf` 系ライブラリの設定保存（Next.js telemetry 等） | `~/Library/Preferences/` | 未対応。大半は黙って失敗するだけで実害なし |
| `ps` / `launchctl` など XPC 系ツール | — | 既知。dotfiles は cage 除外済み |

cage 以外で worktree 特有の「動かない」もあるので併記する:

- `.env` や `node_modules` など gitignore 対象は worktree に複製されない（手動コピー / `npm install` が必要）
- 本体と同じポート（HJN は 3262）で dev サーバを起動すると衝突する

## 対策（実施内容）

1. **`-allow-git` を付けて cage を起動**（`.emacs.d/elisp/claude-code-projects.el` の `--get-command`、`.zshrc` の `claude`）
   - cage 0.1.13 の組み込み機能。起動ディレクトリから `git rev-parse --git-common-dir` を解決し、その場所への書き込みを許可する
   - 許可されるのは本体の `.git` だけで、本体の作業ツリーは対象外（最小権限）
   - トレードオフ: `.git/hooks` や `.git/config`（`core.fsmonitor` 等）も書けるようになるため、
     caged セッションが仕込んだ hook が、後で cage 外から git を使ったときに実行されうる。
     worktree で git を使う以上は避けられない範囲として許容
   - git リポジトリ外では警告が出るため、リポジトリ内でのみ付与する
   - `.zshrc` の `claude` は alias から関数に変更（条件分岐のため）
2. **caged セッション起動時に毎回 `bin/update-cage-config` を実行**（`claude-code-projects--cage-sync`）
   - 冪等・約0.1秒・worktree マーカーブロックは保持される
   - mtime 比較では不十分: worktree 追加で cage 設定が書き換わり、`projects.yml` より新しく見えてしまう（今回の HJN がまさにこの状態だった）
   - 失敗しても警告のみで起動は続行
3. **ダッシュボードのプロジェクト登録後に `update-cage-config` を実行**（`bin/generate-project-dashboard`）
4. **今回分の復旧**: `update-cage-config` を手動実行し、`/Users/pongchang/HJN` を許可リストに追加済み

## 既存セッションへの影響

cage（macOS sandbox）のプロファイルは**プロセス起動時に固定**され、後から変更できない。
修正前に起動したセッションは、設定ファイルを直しても古い制限のまま動き続ける。
→ HJN の worktree セッション 2 つは再起動が必要。
