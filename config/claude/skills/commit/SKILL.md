---
name: commit
description: Use this skill when committing changes. This skill enforces writing meaningful commit messages with structured contextual action lines, and provides Git workflow guidelines.
---

# Commit

このスキルはコミットのワークフロー全体をカバーする。

## 絶対禁止事項

- **`git commit --amend` は禁止**: 履歴を直線的に保つため
- **`git reset --soft|hard` は禁止**: 変更の巻き戻しは行わない
- **コンテキストのないコミットは禁止**: 必ず body に action line を 1 つ以上記述する
- **会話中に作業していない変更をコミットすることは禁止**: `git status` で表示された変更であっても、その会話セッション中に自分が行った変更のみをコミットすること。関係のない変更が存在する場合は無視する
- **GitHub の Issue/PR 参照は禁止**: `Closes #123`、`Fixes #123`、`https://github.com/.../issues/123`、`https://github.com/.../pull/123` などの issue/PR 参照は一切記載しない。OSS の issue や PR にリンクされることを避けるため

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

**必須**。空行を挟んで、contextual action lines を使って変更のコンテキストを記述する。

action line のフォーマット:

```
<action-type>(<scope>): <content>
```

利用可能な action type:

| type         | 用途                             | 例                                                                       |
| ------------ | -------------------------------- | ------------------------------------------------------------------------ |
| `intent`     | 変更の目的・動機                 | `intent(auth): reduce session token size to stay under 4KB cookie limit` |
| `decision`   | 選択したアプローチと理由         | `decision(cache): Redis over Memcached for pub/sub support`              |
| `rejected`   | 却下した選択肢と理由             | `rejected(cache): in-memory store — doesn't survive process restart`     |
| `constraint` | 選択を制約した条件・限界         | `constraint(api): max 30s timeout enforced by upstream gateway`          |
| `learned`    | 調査・試行で判明した非自明な挙動 | `learned(puppeteer): requires --no-sandbox flag inside Docker`           |

ルール:

- **`intent` は必須**。変更の目的が subject から自明でない限り必ず書く
- その他の action type は**該当する場合のみ**書く (additive — 全部埋めなくてよい)
- **diff から読み取れる情報は書かない** — action line はコードに現れないコンテキストを記録するためのもの
- `scope` は subject の scope と同じで構わない。省略不可

## 良い例

```
zsh: fix EDITOR being set to "nvim not found"

intent(zsh): ensure EDITOR is set to a valid nvim path
learned(zsh): `$(which nvim)` runs before mise initializes PATH,
  causing `which nvim` to output "nvim not found" which was then
  set as EDITOR — broke git rebase -i by opening "not"/"found" as files
```

```
tmux: add visual distinction for inactive panes

intent(tmux): make it easier to identify the active pane in multi-pane layouts
decision(tmux): dim inactive panes over using a border highlight — subtler and
  works across all terminal color schemes
```

```
nvim/cmp: disable completion in comment contexts

intent(nvim/cmp): stop autocompletion from triggering in comments
```

## 悪い例

```
zsh: simplify EDITOR to use nvim directly
```

- 問題: body がない。なぜ simplify が必要だったのか不明

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

intent(<scope>): <purpose>
decision(<scope>): <chosen approach and reason>  # 該当する場合のみ
rejected(<scope>): <discarded option — reason>   # 該当する場合のみ
constraint(<scope>): <hard limit or boundary>    # 該当する場合のみ
learned(<scope>): <non-obvious behavior found>   # 該当する場合のみ
EOF
)"
```

5. `git status` で成功を確認

## pre-commit フック

- フックが失敗した場合: 問題を修正し、**元のメッセージを使用して**再度コミット
- フックがファイルを変更した場合 (フォーマッタなど): 変更されたファイルを add して再度コミット

## セルフチェック

コミット前に以下を確認:

1. `intent` action line が書かれているか?
2. Subject は「何を直した」になっているか? (問題解決の場合)
3. 1 つの論理的なまとまりになっているか?
4. diff から読み取れる情報を action line に重複して書いていないか?
