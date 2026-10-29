---
name: create-pr
description: Use this skill when creating or updating a Pull Request. This skill provides the workflow for drafting, reviewing, and submitting PRs using a ai pr-draft command. Also use when updating an existing PR's title and body.
---

# Create PR

以下の手順で PR を作成する。

**重要:** diff は「Base branch の解決」で定めた base ref と比較すること。default branch の ref は必ず remote (`origin/<default_branch>`) を使う。ローカルの default branch は古い可能性がある。

## Conditions

Resolve these before anything else. Values come from the `## Repository facts` list injected at session start. If the list is absent, or a value used below is `unset`, run `gen-claude-template context repo-facts` from the repo directory to print it. If a value is still `unset`, ask the user instead of continuing. Do not infer a value from anywhere else.

`references/` and `scripts/` below are relative to this skill's directory, `~/.agents/skills/create-pr/`.

Derived value:

- `english_output`: true when `repo.visibility` is `PUBLIC` **and** `repo.language` is not `ja`, otherwise false. `repo.visibility: PUBLIC` alone does not make it true.
- `vibe_mode`: resolve with `~/.agents/skills/delegate/references/vibe-policy.md`. Before each vibe-only report or submit, repeat both checks and continue only if the initial `vibe_mode` is still permitted.

Read `references/draft-manual.md` before starting Step 1. It covers Steps 1, 2 and 4.

Apply every row below whose condition holds. The rows are independent of each other.

| Condition                                        | Effect                                                                                                                                                                                                                                                                                                                                          |
| ------------------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `vibe_mode` is true                              | Skip crit review, notify the delegator with the draft and wait for explicit approval before submitting with `--no-review`; report PR ready after CI passes or only `vrt` fails (Step 7). Keep self-review and CI monitoring. Even when `is_master_push_repo` is true, create a PR from the current branch and never push to the default branch. |
| `english_output` is true                         | Translation to English is required. The reference covers it in Step 4; Step 5 requires a Japanese-free title and body.                                                                                                                                                                                                                          |
| `english_output` is false                        | No translation happens.                                                                                                                                                                                                                                                                                                                         |
| `repo.owner` is `fohte`                          | Skip Step 8.                                                                                                                                                                                                                                                                                                                                    |
| `has_release_please` is `true`                   | Rule 1 uses Conventional Commits; otherwise `<scope>: <description>`. `scripts/render-rules` already applies it when it prints the rules.                                                                                                                                                                                                       |
| `scripts/find-pr-template` prints a template     | The rules embed it as the PR structure; otherwise they use the default Why/What structure. `scripts/render-rules` already applies it.                                                                                                                                                                                                           |
| ... and the template contains `Design decisions` | The rules include Rule 9; otherwise there is no Rule 9. `scripts/render-rules` already applies it.                                                                                                                                                                                                                                              |

## Step 0 より前の upstream 同期

同期または Base branch の解決で作業を止める場合、`vibe_mode` では前提の誤りとして委任元に報告する。

GitHub は下段 PR の merge 後に上段 PR の remote branch を rebase して base を付け替えるため、upstream が `origin/<現在の branch>` の場合だけ、diff、crit review、push の前にローカル branch を同期する ([GitHub docs](https://docs.github.com/en/pull-requests/how-tos/merge-and-close-pull-requests/merging-stacked-pull-requests))。

```bash
branch=$(git branch --show-current)
upstream_remote=$(git config --get "branch.$branch.remote" || true)
upstream_merge=$(git config --get "branch.$branch.merge" || true)
if [[ "$upstream_remote" == "origin" && "$upstream_merge" == "refs/heads/$branch" ]]; then
  git pull --rebase
fi
```

upstream がない場合、別の branch、または別 remote を指す場合は同期しない。`git pull --rebase` が失敗したら作業を止め、エラー内容を報告する。作業ツリーの変更が原因なら、変更を commit または stash してから再実行する。

## Base branch の解決

`base_branch` は diff、crit review、`review-draft`、submit で使う PR の base。`stack_parent_branch` と `stack_parent_pr_number` は、新しい PR を open PR に積む場合だけ設定する。

1. 現在の branch に open PR があれば、`gh pr list --state open --head "$(git branch --show-current)" --json number,baseRefName` で確認した `baseRefName` を `base_branch` に使う。既存 PR の更新では base を変更せず、`stack_parent_branch` / `stack_parent_pr_number` は設定しない。該当 PR が複数ある場合は曖昧さを報告して止める。
2. 現在の branch に open PR がなく、ユーザーまたは委任元が下段 PR の branch を指定していれば、その branch を使う。`gh pr list --state open --head "<指定 branch>" --json number,headRefName,headRepository,isCrossRepository` で完全一致する open PR を確認し、その PR が同じ repository に 1 件だけある場合は `headRefName` を `base_branch` / `stack_parent_branch` に、`number` を `stack_parent_pr_number` に設定する。該当 PR がない、複数ある、または別 repository の場合は前提の誤りとして報告して止める。
3. 明示指定がなければ `git fetch origin` を 1 回実行してから、自動判定する。`gh repo view --json nameWithOwner --jq .nameWithOwner` で現在の repository を確認し、`gh pr list --state open --limit 1000 --json number,headRefName,headRefOid,headRepository,isCrossRepository` で open PR を取得する。全体 fetch または一覧取得に失敗した場合は作業を止めて報告する。個別 PR の参照を確認できない場合は、その PR だけを候補から外す。
    - `headRepository.nameWithOwner` が現在の repository と一致し、`isCrossRepository` が `false` の PR だけを見る。PR の情報が欠けている場合、`origin/<headRefName>` がない場合、`git rev-parse origin/<headRefName>` と `headRefOid` が異なる場合、または shallow clone などで履歴を判定できない場合は、その PR だけを候補から外す。
    - `shared_commit=$(git merge-base HEAD "origin/<headRefName>")` を求める。値があり、`shared_commit` が `origin/$(git main)` の祖先でなければ候補にする。下段 PR に後から commit が追加されても、現在の branch と共有する PR 固有 commit が候補判定に使われる。
    - 候補が 1 件なら選ぶ。複数ある場合は、共有 commit がほかの全候補の共有 commit の子孫である候補が一意ならそれを選ぶ。それ以外は曖昧さを報告して止める。`vibe_mode` では前提の誤りとして委任元に報告する。
    - 選んだ PR の `headRefName` を `base_branch` / `stack_parent_branch` に、`number` を `stack_parent_pr_number` に設定する。
4. 候補がなければ `base_branch` に default branch (`git main`) を設定し、stack 用変数は設定しない。fork から新しい PR を作る場合も default branch を使う。stack は同じ repository の branch 間だけで作成できる。

`base_ref` には `origin/<base_branch>` を使う。必要な remote ref がなければ `origin` から取得する。

各 step では次の値を使う。

| 用途                | 指定                                                                                                                                 |
| ------------------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| diff と crit review | default branch では crit の自動検出を使い、それ以外では `base_ref` を `crit-approval-review` に明示して渡す                          |
| `review-draft`      | default branch 以外なら `base_branch` を引数に渡す                                                                                   |
| submit              | `stack_parent_branch` がある新規 PR だけ `--base <stack_parent_branch>` を渡す。既存 PR の更新と default branch 向け PR では省略する |

## 開始時の宣言 (必須・最初の応答で実行)

create-pr skill を起動したら、**最初の応答で**適用される必須ステップを列挙し、これから実行する旨を宣言すること。宣言なしに Step 1 以降に進むのは禁止。

- Step 0: 未 push コミットの push (`commit` skill の push 手順に従う) と、branch の diff の crit レビュー (`crit-approval-review` skill)。`vibe_mode` では push のみ実施し、crit レビューを省く
- Step 2: `lint-draft.ts` による機械的な検査と、文脈を持たないレビュアーによる PR body のレビュー
- Step 3-4: editor によるレビューと指示への対応。通常フローで実施し、`vibe_mode` では draft を添えて委任元へ通知し、明示的な承認を受けるまで submit しない

「小さい PR だから」「変更が単純だから」「明らかに問題ないから」「効率を優先したい」を理由としたスキップは禁止。これらは典型的な自己判断スキップシグナルで、検出したら必ず実行する。skill のテキストに「必須」「スキップ禁止」と書かれているステップを Claude 側の判断で省略しない。スキップしてよいのはユーザーが該当ステップを名指しで明示的に skip 指示した場合のみ。

## 0. push と diff の crit レビュー (必須)

必須 reviewer が同じ engine で 1 回 retry した後も未評価、または結果が `invalid` / `partial` / `empty` の場合は、`push` / draft 作成 / `submit` のいずれにも進まない。

未 push のコミットがあれば `commit` skill の push 手順 (`self-review` skill でのレビュー → 🔴/🟡 対応 → `git push`) に従って push する。
`vibe_mode` では `crit-approval-review` を実行しない。push と commit skill の self-review は通常どおり行う。
`self-review` はこの skill から直接呼び出さない。呼び出しは `commit` skill 側の責務とし、二重実行を避ける。

```bash
git log @{u}..HEAD --oneline
# upstream 未設定なら
# $base_branch は「Base branch の解決」で確定した branch 名に置き換えてから実行する
git log "origin/$base_branch..HEAD" --oneline
```

未 push のコミットがなければ push は不要。

`vibe_mode` でない場合は、push の要否にかかわらず `crit-approval-review` skill で base branch との diff をユーザーにレビューしてもらい、承認されるまで Step 1 に進まない。base ref は「Base branch の解決」の crit review の指定に従う。

通常フローでは承認後に `commit` skill の push 手順に従って loop 中の修正をまとめてコミット・push し、Step 1 に進む。`vibe_mode` では crit 承認を待たずに Step 1 に進む。

## 1. PR body のドラフトを作成する

ドラフトは **常に日本語で書くこと**。日本語の文体・表現については `yomiyasu` skill の規範に従う (非生物主語の解体、比喩動詞の具体化など)。

`references/draft-manual.md` の Step 1 に従う。

## 2. ドラフトのレビュー (必須・スキップ禁止)

`references/draft-manual.md` の Step 2 に従う。
`review-draft` の base は「Base branch の解決」の指定に従う。

## 3. レビュー

`vibe_mode` では editor を開かず、draft を作成した後に委任元のレビューを待つ。`<vibe-draft-ready>` を送る直前に共通 policy を再確認し、初回判定時から許可が続いている場合だけ通知する。許可がなくなっていた場合は通常フローに戻り、crit review の承認を得て editor review を完了する。vibe 報告は送らない。委任元に `notify` してよいのは draft ready、PR ready、またはこの指示の前提が誤っていると判明した場合だけとする。進捗、質問、待ち状態は通知しない。通知後はターンを終えて委任元の返答を待つ。

draft ready、PR ready、前提誤りを通知するときは、`a agent peer parent | jq -r '.[0].session_id // empty'` で委任元の session ID を取得し、`a agent peer notify --message <MESSAGE> <SESSION_ID>` で送る。session ID が空、または `notify` が `ended` エラーで失敗した場合は、宛先を推測せずユーザーに報告する。

draft の絶対パス、ブランチ名、現在の HEAD SHA、チェックリスト項目 ID を含む次の形式で `<vibe-draft-ready>` を作る。draft のパスは `~/.agents/skills/create-pr/scripts/draft-path` の出力、ブランチ名は `git branch --show-current`、HEAD SHA は `git rev-parse HEAD` で取得する。チェックリスト項目 ID は `branch.<ブランチ名>.x-tq-checklist-item-id` から取得する。値が無い場合は `none` を使う。チェックリスト leaf の項目 ID は委任元が報告を照合するときに検証する。

```text
<vibe-draft-ready>
Draft: <draft-path の出力>
Branch: <ブランチ名>
Head SHA: <HEAD SHA>
tq checklist item ID: <チェックリスト項目 ID>
enable-vibe-coding skill の『draft ready を受けたら』の手順に従う。
</vibe-draft-ready>
```

通知後は `a agent status set wait "review of <repo-name> PR draft"` を実行して turn を止める (`<repo-name>` は `repo.name`)。`sleep` ツールやコマンドで turn 内に留まって待たない。委任元の返答は新しい turn として届く。返答で再開するまで待ち、再開後も承認なしに Step 5 へ進まない。

`vibe_mode` でない通常フローでは、次の `a ai pr-draft review` 手順で editor を開く。

`a ai pr-draft review` を **バックグラウンドで** (`run_in_background: true`) 実行。完了を待ち、exit code で判断する:

- exit code 0 / 1: エディタが閉じた。0 は `steps` のいずれかが変わったこと、1 は変わらなかったことしか意味せず、**どちらも承認を意味しない**。次に進んでよいかは stdout を読んで Step 4 で判断する
- exit code 2: エディタが既に開いている。**追加アクションは不要**。ユーザーにエディタ上でファイルを読み込み直すよう伝える (例: Neovim なら `:e`)。再度 review コマンドを実行したり、エディタを閉じるよう促してはならない
- exit code 3: ターミナルエミュレータが起動できなかった (macOS スリープ中などで 10s 内に起動失敗)。ロックファイルは残らないので、ユーザーにターミナルが利用可能になってから再実行を依頼する。自動でリトライしてはならない (スリープ状態が解消されない限り再失敗するため)
- exit code 4: review pane がレビュー完了前に消えた (pane のプロセスが外部から kill されたなど)。ユーザーはまだレビューしていないので、承認の有無を判断せず `a ai pr-draft review` をバックグラウンドで再実行する。再実行も exit code 4 で終わったら、それ以上は再実行せずユーザーに報告する

**polling 禁止**: バックグラウンドで起動した後は `<task-notification>` の完了通知が届くまで何もしない。`while`/`sleep` ループや出力ファイルの繰り返し読み取りで進捗確認してはならない。これは `a ai pr-draft review` だけでなく `a ai review wait` や `gh pr checks --watch` など本スキル内のすべてのバックグラウンドコマンドに共通。

## 4. ユーザーの指示に応じた対応

`vibe_mode` では Step 3 の委任元の返答に応じて対応する。

- 「draft にコメントを書いた」: 委任元が draft に直接コメントを書いている。コメントを重ねて追加せず、`references/draft-manual.md` の Step 4 で反映する。更新した draft を確認し、Step 3 に戻って `<vibe-draft-ready>` を再度送る。
- 「コードを直して」: 指摘に合わせてコードを修正し、`commit` skill の手順で commit と push を行う。Step 1 から draft を作り直す。
- 「承認」: `english_output` が true の場合は `references/draft-manual.md` の Step 4 で翻訳する。翻訳後は flag を false に戻し、title と body が英語であることを確認して Step 5 に進む。`english_output` が false の場合は翻訳せず Step 5 に進む。

以下の editor review の stdout 判定は `vibe_mode` でない通常フローに適用する。

**バックグラウンド実行の stdout を必ず読んでから分岐する。** stdout はエディタ編集前後の unified diff (無編集なら `(no edits)`) で、frontmatter の `steps` の変化とユーザーが本文に書き込んだコメントの両方が出る。review はエディタを開く前に `steps` を全て false に戻すので、この diff だけで今どの段階かが確定する。

- diff に `submit: true` がある: Step 5 へ
- ない (`ready-for-translation: true` のみ、本文へのコメント、`(no edits)`): まだ途中段階。`references/draft-manual.md` の Step 4 の対応をして Step 3 に戻る。`submit: true` が出るまで何周でも回す

## 5. Submit

stack を作成するには armyknife v0.1.497 以降が必要。古い `a` は `--base` を受け付けても stack を作らず、警告も出さない。

```bash
a ai pr-draft submit [--base <stack_parent_branch>]
```

既存 PR がある場合は title と body を更新する。通常フローではユーザー承認済みの場合のみ submit する。
submit 直前に共通 policy を再確認する。初回判定時から許可が続いている場合だけ、Step 3 で委任元の明示的な承認を受けた後に `a ai pr-draft submit [--base <stack_parent_branch>] --no-review` を使う。それ以外は通常フローに切り替え、未実施の crit と editor review を終えて人間の承認を受けてから `--no-review` なしで submit する。
`english_output` が true のときは、title と body に日本語が含まれていないこと。

`--base` の指定は「Base branch の解決」に従う。
submit の `stderr` に stack 作成の警告が出た場合、submit 自体は成功しても PR は stack に入っていない。警告の内容と出力された command を確認し、条件に合う復旧方法だけを使う。

- 下段 PR が既存 stack の途中にある警告は復旧 command を出さない。この場合は command を作らず、stack に入らなかったことを報告する。
- stack の読み取りに失敗した警告では、まず出力された状態確認 command を実行する。下段 PR の状態は `gh api "repos/<owner>/<repo>/pulls/<下段 PR の番号>" --jq .stack` で確認し、`.position` と `.size` が等しければ最上段と判断する。stack がなければ作成 command、最上段なら追加 command のどちらか一方だけを使う。最上段でなければ追加しない。
- `<stack_number>` などは実際の値に置き換える。command が出力されなかった場合は作らず、placeholder が残る command も実行しない。

復旧 command が失敗した場合は、推測した command で再試行せず、警告と出力された command を最終報告に含める。

公開計画が保存され、branch config に `x-tq-task-id` と `x-tq-checklist-item-id` の両方がある場合、submit が tq の葉への PR リンクと分割 PR の全体像の同期を行う。どれかの条件がない場合は自動処理を行わない。submit は同期に失敗しても成功扱いになるため、`stderr` に復旧コマンドが出た場合は表示どおりに実行する。

## 6. tq タスクへのリンク登録

公開計画があり、branch config に `x-tq-task-id` と `x-tq-checklist-item-id` の両方がある場合は submit が葉にリンクする。それ以外の場合はこの Step の手動リンクで補う。同じ PR を同じ葉に再度紐付けても既存の task link が使われるため、submit の自動リンク後も以下の手順を実行できる。

委任元が `branch.<name>.x-tq-checklist-item-id` に PR 項目 ID を残していれば、`tq checklist item update <itemId> --github <pr_url>` でその項目にリンクする。これにより tq task にも GitHub link が作られる。項目 ID が無い場合は、`branch.<name>.x-tq-task-id` に ID があればそれをタスクのリンク先にし、セッション側の結果で上書きしない。
branch の task ID は worktree 専用で、session は複数作業にまたがることがあるため、branch の task ID を `TQ_SESSION_ID` からの推定より優先する。

task ID の branch config が無いときは、このセッション (`$TQ_SESSION_ID`) にリンクされている tq タスクから決める。
複数件リンクされていても、そこに親子関係があるなら子が作業対象なので一意に決まる。
`tasks[]` の `parentId` が別の linked task の `id` を指していれば親子で、親は捨てて子 (葉) を残す。

```bash
~/.agents/skills/create-pr/scripts/link-tq-task --author <自分のモデル名>
```

リンクも branch config も無いなら何もしない。
葉が複数件残る (兄弟タスクが並んでいる) ときは、script が候補を表示して終了する。候補の title と PR の内容を突き合わせて自分で決め、`tq_task_id=<選んだ task ID>` を設定して同じ script を再実行する。
ユーザーに聞かない。
選んだ task と根拠は最後の報告に 1 行で書き、後から誤リンクを見つけられるようにする。
**黙って飛ばして PR 作成を完了扱いにしない。**

`--author` には自分のモデル名を渡す (`tq` skill 参照)。同じ PR をチェックリスト項目に再度紐付けても、tq は既存の task link を使って項目を更新する。別タスクにリンク済みの PR などで紐付けに失敗した場合は、script がエラーを返すので調査する。

## 7. CI 実行を監視

`gh pr checks --watch` で CI を監視。失敗したら調査・修正して再 push。
`vibe_mode` では CI が green になり、該当時は Step 8 も済ませた後、共通 policy を再確認する。初回判定時から許可が続いている場合だけ、次の形式で委任元へ報告する。許可がなくなっていた場合は vibe 報告を送らず、通常の人間レビューに委ねる。PR URL とチェックリスト項目 ID は実際の値に置き換える。チェックリスト項目のない委任では `none` を使う。

`vrt` commit status 以外がすべて green で、`vrt` だけが失敗しているときも報告する。VRT 差分の確認と承認ラベルの付与は委任元が担うため、委任先はユーザーに VRT レビューを頼まず、`vrt-approved` を待たず、自分でも付けない。リポジトリの規約が「VRT 差分はユーザーにレビューを頼む」としていても、vibe ではこの報告がその依頼の代わりになる。

```text
<vibe-pr-ready>
PR: <PR URL>
Head SHA: <git rev-parse HEAD の値>
tq checklist item ID: <branch.<name>.x-tq-checklist-item-id の値>
enable-vibe-coding skill の『PR ready を受けたら』の手順に従う。
</vibe-pr-ready>
```

通知後は `a agent status set wait "merge of <repo-name> PR <number>"` を実行 (`<repo-name>`=`repo.name`、`<number>`=PR URL 末尾の番号) して turn を止める。draft ready のときと同じく turn 内に留まって待たない。turn が続いている session は merge 後に `a agent close` で閉じられない。

差し戻しを反映して再 submit した場合も、同じ条件で同じ形式で再報告する。

## 8. レビューコメントを確認して対応する

`repo.owner` が `fohte` のときはこの Step を実行しない。

**CI や bot のチェックが `pass` でもレビューコメントは付く。CI pass = レビュー指摘なし ではない。** submit 後は必ず `/check-pr-review` skill を実行し、CodeRabbit / Devin 等の自動レビューと人間のコメントを確認して対応する。

`check-pr-review` skill の中断・省略は禁止。
