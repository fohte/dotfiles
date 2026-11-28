---
name: github
description: Up-to-date knowledge of GitHub features that may postdate the model's training data, such as stacked pull requests and how they merge, plus which dedicated skill to use instead of running `gh` directly. Use this skill whenever writing or reviewing a merge order or release plan that spans multiple PRs, planning PRs that depend on each other, or merging, rebasing, syncing the base of, restructuring, or reviewing a PR that belongs to a stack (including inserting a PR into a stack) — even when no PR is being created. Also use it before running `gh issue` or `gh pr` commands that view, create, edit, or comment on issues and PRs.
---

# GitHub

knowledge cutoff より後に追加・変更された GitHub の仕様を references で補う。扱う対象に合う reference だけを読む。

| 対象                                                                  | 読む reference              |
| --------------------------------------------------------------------- | --------------------------- |
| stacked PR (作成、base の取り込み、構成の変更、merge、merge 順の計画) | `references/stacked-prs.md` |

## `gh` で直接操作しない

次の操作は `gh` を直接実行せず、対応する skill を使う。専用 skill は、draft のレビューや未解決 thread の取得など、`gh` を直接実行すると抜ける手順を持つため。

| 操作                               | 直接実行しない command                                   | 使う skill        |
| ---------------------------------- | -------------------------------------------------------- | ----------------- |
| Issue の閲覧、作成、編集、コメント | `gh issue view` / `create` / `edit` / `comment`          | `github-issue`    |
| PR の作成、title と body の更新    | `gh pr create` / `gh pr edit`                            | `create-pr`       |
| PR のレビューコメントの確認と対応  | `gh pr view --comments`、`gh api` でのコメント取得・返信 | `check-pr-review` |
