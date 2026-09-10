# .claude-dotfiles/ — 未配線・非デプロイ（放置中）

**これは「使われていない」ディレクトリです。消す前にこのメモを読んでください。**

## 何だったか

元々の意図: 設定を2階層に分ける括りだった。

- `.claude/`（リポジトリ直下）= **PC全体＝グローバル**設定。`~/.claude` がここへの symlink で、全プロジェクトに効く。
- `.claude-dotfiles/`（ここ）= **dotfiles プロジェクト専用**の Claude 設定にするつもりだった箱。

## なぜ効いていないか

1. Claude Code はプロジェクト設定を **`.claude/` から読む** — `.claude-dotfiles/` という名前は読まない。
2. `Makefile` の `EXCLUSIONS` に入っていて **deploy もされない**。
3. dotfiles リポジトリでは `.claude/`（グローバルの実体）とプロジェクトの `.claude/` が **同じディレクトリに重なる**（symlink のため）。専用設定を同じ `.claude/` 名で分離できず、別名にしたが読まれない、という手詰まり。

## いま専用の指示はどこに書くか

**リポジトリ直下の `CLAUDE.md`** が dotfiles プロジェクト専用の指示として機能する（グローバルの `~/.claude/CLAUDE.md` とは別ファイルで、他プロジェクトには漏れない）。専用ルールはそこへ書く。

## 中身

commands / hooks(scripts+lib) / personas / plan など、2026年3月時点の旧・機能セット。現行 `.claude/` が同領域をカバー済み。参照用として残しているだけ。

## 扱い

- **コンテキストには載らない**（Claude Code が読まないため）＝置いてあってもトークンコスト0・実害なし。
- 本気で「dotfiles 専用の commands/hooks を分けたい」なら、グローバル実体を別パスへ移して symlink を張り替える等の機構変更が必要（deploy・settings.json の `$HOME/.claude/...`・cage・rules ロードに波及）。リターン小・リスク大のため現状は放置。
