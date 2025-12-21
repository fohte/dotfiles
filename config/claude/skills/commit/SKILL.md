---
name: commit
description: Use this skill when committing changes. This skill enforces writing meaningful commit messages with both Why and What sections, and provides Git workflow guidelines.
---

# Commit

このスキルはコミットのワークフロー全体をカバーする。

## 絶対禁止事項

- **`git commit --amend` は禁止**: 履歴を直線的に保つため
- **`git reset --soft|hard` は禁止**: 変更の巻き戻しは行わない
- **一行だけの what コミットは禁止**: 必ず Why を記述する

## コミットの粒度

- 論理的なチェックポイントでコミットすること
- 1 つの機能、1 つの修正、または 1 つのまとまった変更につき 1 コミット
- 複数の独立した変更を 1 コミットにまとめない

## コミットメッセージフォーマット

```
<scope>: <subject>

<body>
```

### Subject line (1 行目)

- **スコープ**: 変更対象の設定ディレクトリを指定 (例: `zsh`, `nvim`, `tmux`, `bin`)
  - 機能単位やスクリプト名で細分化可能 (例: `zsh/history`, `nvim/cmp`, `bin/tmux-session-fzf`)
  - 複数スコープの場合は `, ` で区切る (例: `claude, bin`)
- **説明**: 小文字で始まり、現在形の命令形を使用 (例: `add`, `fix`, `refactor`, `update`, `remove`)
- **問題を解決する場合**: 「何をした」ではなく「何を直した」を書く
  - Good: `fix EDITOR being set to "nvim not found"`
  - Bad: `simplify EDITOR to use nvim directly`

### Body (2 行目以降)

**必須**。空行を挟んで Why と What を記述する。

- **Why**: なぜこの変更が必要なのか。問題の原因、背景、動機を説明
- **What** (任意): 変更内容の詳細。subject だけで十分に説明できている場合は省略可

## 良い例

```
zsh: fix EDITOR being set to "nvim not found"

`$(which nvim)` was executed before mise initialized PATH, causing
`which nvim` to output "nvim not found" which was then set as EDITOR.
This broke git rebase -i by opening "not" and "found" as files.
```

```
tmux: add visual distinction for inactive panes

In multi-pane layouts, it was difficult to identify which pane was
active. Add dimmed styling to inactive panes to make the active pane
more obvious.
```

```
nvim/cmp: disable completion in comment contexts

Autocompletion in comments was triggering unnecessarily and
interrupting the writing flow.
```

## 悪い例

```
zsh: simplify EDITOR to use nvim directly
```
- 問題: Why がない。なぜ simplify が必要だったのか不明

```
zsh: update vim.zsh
```
- 問題: 何をしたのか分からない。body もない

```
fix bug
```
- 問題: scope がない。何のバグか分からない。body もない

## コミット手順

1. `git status` で変更内容を確認
2. `git diff` でステージング前の差分を確認
3. `git log --oneline -5` で最近のコミットスタイルを確認
4. 変更を add してコミット (HEREDOC を使用してフォーマットを保持):

```bash
git add <files>
git commit -m "$(cat <<'EOF'
<scope>: <subject>

<body - Why と What を記述>

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

5. `git status` で成功を確認

## pre-commit フック

- フックが失敗した場合: 問題を修正し、**元のメッセージを使用して**再度コミット
- フックがファイルを変更した場合 (フォーマッタなど): 変更されたファイルを add して再度コミット

## セルフチェック

コミット前に以下を確認:
1. Why が書かれているか?
2. Subject は「何を直した」になっているか? (問題解決の場合)
3. 1 つの論理的なまとまりになっているか?
