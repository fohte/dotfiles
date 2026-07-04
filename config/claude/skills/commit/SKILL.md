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
- **GitHub の Issue/PR 参照は禁止**: `#123`、`PR #123`、`Closes #123`、`Fixes #123`、`https://github.com/.../issues/123`、`https://github.com/.../pull/123` などの issue/PR 番号への参照は一切記載しない。`#数字` はコミット先リポジトリの issue にリンクされてしまうため、たとえ別リポジトリの PR/issue を意図していても使用禁止。代わりに自然言語で記述する (例: `PR #616 のマージ完了` → `API Token 権限拡張のマージ完了`)

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
4. 変更を `git add` でステージング
5. コミット (HEREDOC を使用してフォーマットを保持):

```bash
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

6. `git status` で成功を確認
7. **`self-review` skill でレビュー (条件付き必須、1 回のみ)**: push する前に、これから push する全コミットをまとめてレビューする。省略可能な条件と、🔴 Critical / 🟡 Warning への対応方針は下記「push 前レビュー」を参照
8. `git push` (upstream 未設定の場合は `git push -u origin HEAD`)

## push 前レビュー

`git push` の前に、その push に含まれる全コミットをまとめて `self-review` skill でレビューする。
skill は 3 観点グループ (behavior / structure / convention) の subagent を並列起動し、13 観点の統合レポートを返す。
**レビューは 1 回の push につき 1 回だけ実行する**。
コミットのたびに繰り返さない。
修正コミットを追加した後も再実行しない。

```bash
# push に含まれる差分を取得
git diff @{u}..HEAD
# upstream が未設定の場合は対象ブランチを明示
git diff origin/master..HEAD
```

省略可能なのは**以下を全て満たす場合のみ**:

- 変更ファイルが 1 つ以下、追加・削除合わせて 5 行以下
- 内容が typo 修正・コメント微修正・フォーマット変更・空白調整のいずれかに該当
- ロジック変更・新規ファイル作成・テスト追加・依存追加・設定変更を一切含まない

または、ユーザーが明示的に skip を指示した場合。

「小さいから」「単純だから」「明らかに問題ないから」「効率を優先したい」「変更が局所的だから」を理由とした自己判断のスキップは禁止。条件に少しでも当てはまらないなら実行する。判断に迷うなら実行する。

- 🔴 Critical: 該当コードを修正し、`git add` した上で新規コミットとして追加する (`--amend` 禁止)。
  修正コミットを追加したらそのまま push に進む
- 🟡 Warning: 下記「🟡 Warning の判断ルール」に従い、Claude が自分で判断して対応する

このレビューは `commit` skill の責務。
`create-pr` skill から push する場合も本手順に従い、`create-pr` skill 側で `self-review` を重複して呼び出さない。

### 🟡 Warning の判断ルール

🟡 Warning は **Claude が自分で判断して対応する**。ユーザーへの確認に逃げてはならない。各指摘について以下の 4 択から 1 つを選び、追加コミットを作って push 前にまとめて処理する:

1. **修正**: 該当コードを書き換える。最も一般的な選択肢
2. **doc 化**: 設計上の意図的な挙動 / 制約として残す場合、関数 doc・schema 説明・該当箇所のコードコメントに明記する
3. **テスト pin**: 仕様として固定したい挙動はテストで pin する (regression 検出の手段になる)
4. **受容**: 「現状維持が妥当」と判断したものは何もしない。ただし「なぜ無視してよいか」を 1 行で明示できないなら受容してはならない

選択は Claude の判断で確定する。**選択結果を発話で報告するのは構わないが、「対応してよいか」「別 PR でよいか」をユーザーに尋ねて止まるのは禁止**。

#### ユーザー確認が許される境界 (例外条件)

以下のいずれかに該当する場合のみ、対応前にユーザー確認を取ってよい:

- 新規ファイル群の追加・既存ファイル群の大規模リネーム (10 ファイル以上)
- 外部依存 (新しい crate / package / SDK) の追加
- public API のシグネチャ破壊
- 元のタスクスコープを明らかに超える機能追加 (例: 「bug 修正」依頼に対して新機能の提案)

それ以外 (コメント整理・リファクタ・doc 追記・テスト追加・small fix・スタイル統一・規約遵守) は**全て Claude の判断で完結させる**。1 つの🟡 Warning 群の中に上記境界に該当するものと該当しないものが混在する場合、該当しない方は確認なしで処理し、該当するものだけ確認を取る (= 確認は「全部か無か」ではない)。

#### 典型失敗パターン

Claude は以下の言い回しで確認モードに逃げがち。これらは全て**禁止**:

- 「対応するか別 PR にするかお伺いしたい」
- 「修正方針を確認させてください」
- 「すぐ対応してよいか確認しても良いですか?」
- 「いったんここで止めて方針を聞きたい」

「念のため確認しておくのが安全」という直感が湧いたら、それは確認モードに逃げているシグナル。境界条件 (上記) に該当しないなら自分で判断軸を立てて対応する。

## pre-commit フック

- フックが失敗した場合: 問題を修正し、**元のメッセージを使用して**再度コミット
- フックがファイルを変更した場合 (フォーマッタなど): 変更されたファイルを add して再度コミット

## セルフチェック

コミット前に以下を確認:

1. `intent` action line が書かれているか?
2. Subject は「何を直した」になっているか? (問題解決の場合)
3. 1 つの論理的なまとまりになっているか?
4. diff から読み取れる情報を action line に重複して書いていないか?
