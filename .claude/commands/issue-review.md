---
description: Issueブランチを切替→AIレビュー＆自動修正→Playwright確認→サーバ起動＋手動チェックリスト→OK後にmainへマージしPRクローズ
argument-hint: "[issue番号 | pr <PR番号> | ブランチ名]"
---

# /issue-review

`issue-review-flow` スキル（`~/.claude/skills/issue-review-flow/SKILL.md`）を読み込み、その手順に従って Phase 0〜5 を実行する。

対象: $ARGUMENTS

- 引数が空なら、オープン中の PR 一覧から選んでもらう
- Phase 4 で必ず止まり、ユーザの手動確認 OK を得てからマージする

使用例:

```
/issue-review 23
/issue-review pr 51
/issue-review feature/issue-23-admin-manual-handover
```
