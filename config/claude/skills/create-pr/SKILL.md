---
name: create-pr
description: Use this skill when creating or updating a Pull Request. This skill provides the workflow for drafting, reviewing, and submitting PRs using a ai pr-draft command. Also use when updating an existing PR's title and body.
---

# Create PR

以下の手順で PR を作成する。

**重要:** diff の確認には必ず remote の default branch と比較すること (`git diff "origin/$(git main)...HEAD"`)。ローカルの default branch は古い可能性がある。

## Conditions

Resolve these before anything else. Values come from the `## Repository facts` list injected at session start. If the list is absent, or a value used below is `unset`, run `gen-claude-template context repo-facts` from the repo directory to print it. If a value is still `unset`, ask the user instead of continuing. Do not infer a value from anywhere else.

`references/` and `scripts/` below are relative to this skill's directory, `~/.agents/skills/create-pr/`.

Derived value:

- `english_output`: true when `repo.visibility` is `PUBLIC` **and** `repo.language` is not `ja`, otherwise false. `repo.visibility: PUBLIC` alone does not make it true.

Flow: find the first row that matches and follow its action. Read the reference before starting Step 1.

| Condition              | Action                                                                                                                 |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| `repo.name` is `specs` | Read `references/specs.md`. It replaces Step 1. Steps 2-5 do not exist for this repo; continue at Step 6 after Step 1. |
| `role` is `private`    | Read `references/draft-agy.md`. It covers Steps 1 and 4. Step 2 does not exist.                                        |
| (otherwise)            | Read `references/draft-manual.md`. It covers Steps 1, 2 and 4.                                                         |

The rows below are independent of the flow above and of each other. Apply every row whose condition holds.

| Condition                                        | Effect                                                                                                                                    |
| ------------------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------- |
| `english_output` is true                         | Translation to English is required. The reference covers it in Step 4; Step 5 requires a Japanese-free title and body.                    |
| `english_output` is false                        | No translation happens.                                                                                                                   |
| `repo.owner` is `fohte`                          | Skip Step 8.                                                                                                                              |
| `has_release_please` is `true`                   | Rule 1 uses Conventional Commits; otherwise `<scope>: <description>`. `scripts/render-rules` already applies it when it prints the rules. |
| `scripts/find-pr-template` prints a template     | The rules embed it as the PR structure; otherwise they use the default Why/What structure. `scripts/render-rules` already applies it.     |
| ... and the template contains `Design decisions` | The rules include Rule 9 and Step 2 checks Rule 1-14; otherwise there is no Rule 9. `scripts/render-rules` already applies it.            |

## 開始時の宣言 (必須・最初の応答で実行)

create-pr skill を起動したら、**最初の応答で**以下の必須ステップを列挙し、これから実行する旨を宣言すること。宣言なしに Step 1 以降に進むのは禁止。

- Step 0: 未 push コミットの push (`commit` skill の push 手順に従う) と、branch の diff の crit story 作成 + crit レビュー (承認まで loop 中はコミット・push しない)
- Step 2 (`references/draft-manual.md` を読む場合のみ): PR body セルフレビュー (全ルール照合 + 原則照合 + 減算の独立 3 工程)

「小さい PR だから」「変更が単純だから」「明らかに問題ないから」「効率を優先したい」を理由としたスキップは禁止。これらは典型的な自己判断スキップシグナルで、検出したら必ず実行する。skill のテキストに「必須」「スキップ禁止」と書かれているステップを Claude 側の判断で省略しない。スキップしてよいのはユーザーが該当ステップを名指しで明示的に skip 指示した場合のみ。

## 0. push と diff の crit story 作成 + crit レビュー (必須)

未 push のコミットがあれば `commit` skill の push 手順 (`self-review` skill でのレビュー → 🔴/🟡 対応 → `git push`) に従って push する。
`self-review` はこの skill から直接呼び出さない。呼び出しは `commit` skill 側の責務とし、二重実行を避ける。

```bash
git log @{u}..HEAD --oneline
# upstream 未設定なら
git log "origin/$(git main)..HEAD" --oneline
```

未 push のコミットがなければ push は不要。

push の要否にかかわらず、base branch との diff をユーザーにレビューしてもらい、承認されるまで Step 1 に進まない。委任先の無人セッションでも待つ。手順は以下の 2 段階:

1. `crit:crit-story` skill で story を作成する。story の文章 (prologue の `title` / `overview` / `key_changes` / `risks`、各 chapter の `title` / `summary`) は**日本語で書く**。`crit story --guide` が返す guide 本文は英語だが、それは出力言語の指定ではない
    - `crit:crit-story` の ingest では、client と daemon が同じ story を開いてタブを重複させないよう、次の形で実行する:

        ```bash
        crit story --guide
        crit story --prep <path>
        crit story --story-file <path> --no-open
        crit story --refresh --story-file <path> --no-open
        ```

        `--guide` と `--prep` は出力後に終了し、ブラウザを開かない。`--story-file` は保存後に review daemon を起動し、daemon が最初のタブを開く場合がある。`--no-open` は client 側による 2 枚目のタブを抑止する。story-file の ingest が完了したら、この段階を終了する。bare な `crit story`、`crit story --no-spend`、`crit`、`crit review` はここで実行しない
2. `crit:crit` skill でレビュー loop を回し、承認を待つ。`crit:crit` の Step 1-2 に従い、各 review round で bare な `crit` を 1 回だけバックグラウンド実行する。daemon にブラウザが未接続ならこのコマンドが開き、接続済みなら既存のタブを使う。`crit review` を併用したり、同じ round で起動コマンドを再実行したりしない。`crit story` は story を保存して終了するため、承認待ちのブロックは `crit:crit` 側が担う

指摘への対応は crit の loop 内で完結させる。**loop 中はコミットも push もしない** (= `commit` skill も `self-review` skill も呼ばない)。crit の diff は base branch から working tree までなので、未コミットの修正もそのまま次の round でレビューできる。1 指摘ごとに self-review + コミットを挟むと、承認前の中間状態に重い工程を繰り返すことになる。

1. 指摘を修正する
2. `crit comment --reply-to <id>` で対応内容を返信する (作法は `crit:crit-cli` skill)
3. 修正で diff の構成が変わり story の記述とずれたなら story を作り直す (ingest 時に `--refresh --no-open`)。story の文章が依然として正しい微修正なら作り直さない
4. 次の round に進む

承認された時点で初めて、`commit` skill の push 手順に従って loop 中の修正をまとめてコミット・push し、Step 1 に進む。

## 1. PR body のドラフトを作成する

ドラフトは **常に日本語で書くこと**。日本語の文体・表現については `japanese-tech-writing` skill の規範に従う (一文一行、LLM っぽい空句の禁止、冗長の排除など)。

Conditions の表で選んだ reference の Step 1 に従う。

## 2. セルフレビュー (必須・スキップ禁止)

`references/draft-manual.md` を選んだ場合のみの Step。`references/draft-agy.md` (agy の中で完結する) と `references/specs.md` にはこの Step はない。

`references/draft-manual.md` の Step 2 に従う。

## 3. レビュー

`a ai pr-draft review` を **バックグラウンドで** (`run_in_background: true`) 実行。完了を待ち、exit code で判断する:

- exit code 0 / 1: エディタが閉じた。0 は `steps` のいずれかが変わったこと、1 は変わらなかったことしか意味せず、**どちらも承認を意味しない**。次に進んでよいかは stdout を読んで Step 4 で判断する
- exit code 2: エディタが既に開いている。**追加アクションは不要**。ユーザーにエディタ上でファイルを読み込み直すよう伝える (例: Neovim なら `:e`)。再度 review コマンドを実行したり、エディタを閉じるよう促してはならない
- exit code 3: ターミナルエミュレータが起動できなかった (macOS スリープ中などで 10s 内に起動失敗)。ロックファイルは残らないので、ユーザーにターミナルが利用可能になってから再実行を依頼する。自動でリトライしてはならない (スリープ状態が解消されない限り再失敗するため)

**polling 禁止**: バックグラウンドで起動した後は `<task-notification>` の完了通知が届くまで何もしない。`while`/`sleep` ループや出力ファイルの繰り返し読み取りで進捗確認してはならない。これは `a ai pr-draft review` だけでなく `a ai review wait` や `gh pr checks --watch` など本スキル内のすべてのバックグラウンドコマンドに共通。

## 4. ユーザーの指示に応じた対応

**バックグラウンド実行の stdout を必ず読んでから分岐する。** stdout はエディタ編集前後の unified diff (無編集なら `(no edits)`) で、frontmatter の `steps` の変化とユーザーが本文に書き込んだコメントの両方が出る。review はエディタを開く前に `steps` を全て false に戻すので、この diff だけで今どの段階かが確定する。

- diff に `submit: true` がある: Step 5 へ
- ない (`ready-for-translation: true` のみ、本文へのコメント、`(no edits)`): まだ途中段階。Conditions の表で選んだ reference の Step 4 の対応をして Step 3 に戻る。`submit: true` が出るまで何周でも回す

## 5. Submit

```bash
a ai pr-draft submit [--base main]
```

既存 PR がある場合は title と body を更新する。submit はユーザー承認済みの場合のみ成功する。
`english_output` が true のときは、title と body に日本語が含まれていないこと。

## 6. tq タスクへのリンク登録

委任元が `branch.<name>.x-tq-task-id` に ID を残していれば、それをリンク先にし、セッション側の結果で上書きしない。
セッションは複数の作業にまたがり、親タスクにだけリンクされていることがあるので、この branch 専用に書かれた ID の方が正確である。

branch config が無いときは、このセッション (`$TQ_SESSION_ID`) にリンクされている tq タスクから決める。
複数件リンクされていても、そこに親子関係があるなら子が作業対象なので一意に決まる。
`tasks[]` の `parentId` が別の linked task の `id` を指していれば親子で、親は捨てて子 (葉) を残す。

```bash
tq_task_id=$(git config --get "branch.$(git branch --show-current).x-tq-task-id" || true)
if [ -z "$tq_task_id" ] && [ -n "${TQ_SESSION_ID:-}" ]; then
  session_json=$(tq --author <自分のモデル名 (例: claude-opus-5)> session list --session-id "$TQ_SESSION_ID") \
    || echo "tq session list failed" >&2
  if [ -n "$session_json" ]; then
    leaves=$(echo "$session_json" | jq -c '
      .[0].tasks as $t
      | [$t[] | select(.id as $id | any($t[]; .parentId == $id) | not)]')
    case "$(echo "$leaves" | jq 'length')" in
      0) echo "no tq task linked to this session" >&2 ;;
      1) tq_task_id=$(echo "$leaves" | jq -r '.[0].id') ;;
      *) echo "pick one yourself: $(echo "$leaves" | jq -r '[.[] | "\(.id) #\(.number) \(.title)"] | join(", ")')" >&2 ;;
    esac
  fi
fi
if [ -n "$tq_task_id" ]; then
  pr_url=$(gh pr view --json url -q .url)
  tq --author <自分のモデル名 (例: claude-opus-5)> github link "$tq_task_id" "$pr_url"
fi
```

リンクも branch config も無いなら何もしない。
葉が複数件残る (兄弟タスクが並んでいる) ときは、候補の title と PR の内容を突き合わせて自分で決め、その id で `tq_task_id=<id>` を置いて再実行する。
ユーザーに聞かない。
選んだ task と根拠は最後の報告に 1 行で書き、後から誤リンクを見つけられるようにする。
**黙って飛ばして PR 作成を完了扱いにしない。**

`--author` の指定方法は `tq` skill 参照。
同じ PR に対して既にリンク済みの場合は "already linked" エラーになるが、再実行時の想定内なので無視してよい。

## 7. CI 実行を監視

`gh pr checks --watch` で CI を監視。失敗したら調査・修正して再 push。

## 8. レビューコメントを確認して対応する

`repo.owner` が `fohte` のときはこの Step を実行しない。

**CI や bot のチェックが `pass` でもレビューコメントは付く。CI pass = レビュー指摘なし ではない。** submit 後は必ず `/check-pr-review` skill を実行し、CodeRabbit / Devin 等の自動レビューと人間のコメントを確認して対応する。

`check-pr-review` skill の中断・省略は禁止。
