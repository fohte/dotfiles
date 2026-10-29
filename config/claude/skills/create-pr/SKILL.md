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

## Base branch の解決

### Step 0 より前の stack branch 同期

GitHub は下段 PR が merge されると上段 PR の remote branch を rebase し、base を付け替える。ローカル branch が古いまま diff や push を行わないよう、base branch の解決と Step 0 より先に同期する ([GitHub docs](https://docs.github.com/en/pull-requests/how-tos/merge-and-close-pull-requests/merging-stacked-pull-requests))。

stack PR を作成したときは、後続の実行で下段 PR の merge を確認できるよう、PR 番号と branch 名を現在の branch config に保存する。Step 5 の submit が stack 作成の警告を出さずに成功した場合、または警告に対する復旧後に stack 作成を確認できた場合に保存する。下記の placeholder は base branch 解決で得た値に置き換える。

```bash
git config --local "branch.$(git branch --show-current).x-create-pr-stack-parent-number" "$stack_parent_pr_number"
git config --local "branch.$(git branch --show-current).x-create-pr-stack-parent-branch" "$stack_parent_branch"
```

保存済みの PR 番号がある場合は、`gh pr view <stack_parent_pr_number> --json state --jq .state` で状態を確認する。`MERGED` なら、現在の branch に upstream が設定されていることを確認してから `git pull --rebase` を実行し、成功後に base branch を解決する。`OPEN` なら下段 branch を fetch し、後述の ancestry check で現在の branch に含まれていることを確認する。含まれていなければ `git rebase origin/<stack_parent_branch>` を Step 0 より前に実行する。merge されずに `CLOSED` になっていた場合は、stack の状態を推測せず作業を止めて報告する。fetch、rebase、pull のいずれかが失敗した場合も Step 0 に進まない。

### Base branch の選択

全 step で使う `base_branch` は PR の target branch を表す。`stack_parent_branch` と `stack_parent_pr_number` は、新規 PR を open PR に積む場合だけ設定する。ユーザーまたは委任元が下段 PR の branch を明示している場合は自動検出より優先する。current branch の push 先と明示された branch が同一 repository にあり、明示された branch に open PR がちょうど 1 つあることを確認する。条件を満たさない場合は default branch に fallback せず作業を止めて報告する。既存 PR の base と明示された branch が異なる場合も、再 submit で base を変えず、食い違いを報告する。

1. 現在の branch に open PR があるか `gh pr list --state open --head "$(git branch --show-current)" --json number,baseRefName` で確認する。1 件ならその `baseRefName` を `base_branch` にする。明示された下段 branch がこの base と異なる場合は、既存 PR の再 submit では base を変更できないため作業を止めて食い違いを報告する。0 件なら新規 PR として次へ進み、複数なら曖昧なため作業を止める。closed または merged PR はこの判定に含めない。
2. 新規 PR で明示された下段 branch があれば、open PR 一覧から `headRefName` が完全一致し、`headRepository.nameWithOwner` がこの repository と一致し、`isCrossRepository` が `false` の PR を選ぶ。その PR の branch と番号を `stack_parent_branch` / `stack_parent_pr_number` にし、`base_branch` にも同じ branch 名を使う。
3. 明示指定がなく、current branch の push 先がこの repository の場合は、`gh repo view --json nameWithOwner --jq .nameWithOwner` で repository 名を確認し、`gh pr list --state open --limit 1000 --json number,headRefName,headRefOid,headRepository,isCrossRepository,baseRefName,baseRefOid` で候補を得る。`headRepository.nameWithOwner` がこの repository と一致し、`isCrossRepository` が `false` の PR のみを候補にする。head と base の remote branch ref を fetch してから比較する。各 ref は `git fetch --no-tags origin "refs/heads/<branch>:refs/remotes/origin/<branch>"` で取得する。取得後の ref OID が `headRefOid` / `baseRefOid` と異なる場合は PR 一覧を一度取り直して再計算する。再計算後も一致しない場合、fetch が失敗した場合、または graph が浅く判定できない場合は作業を止めて原因を報告する。

    各 PR について `git merge-base --all HEAD "origin/<headRefName>"` と `git merge-base --all "origin/<headRefName>" "origin/<baseRefName>"` を求める。各結果が 1 commit の場合だけ比較を続ける。前者を `shared_commit`、後者を `pr_base` とし、`shared_commit` が `pr_base` と異なり、`git merge-base --is-ancestor "$pr_base" "$shared_commit"` が成功する PR を候補にする。下段 PR に後から commit が追加されても、上段 branch と共有する古い commit が PR 固有履歴に残っていれば候補になる。候補の `shared_commit` を比較し、ほかの候補すべての共有 commit の子孫にある候補が 1 つだけなら、その PR を選ぶ。候補が複数で前後関係を決められない場合は作業を止めて報告する。

4. 下段 PR が見つからない場合、または push 先が fork の場合は default branch (`git main`) を使う。ただし、ユーザーや委任元から current branch が下段 PR 上に作られたと聞いていて候補が見つからない場合は、default branch に fallback せず状況を報告する。下段 PR が force-push や rebase で共有履歴を失った場合は明示指定を使う。

`stack_parent_branch` が決まったら、fetch 済みの `origin/<stack_parent_branch>` が `HEAD` の祖先か確認する。祖先でなければ `git rebase origin/<stack_parent_branch>` を Step 0 より前に行い、conflict が解決できなければ作業を止める。これにより下段 PR の最新 commit を上段 branch に取り込み、stack の差分と履歴を揃える。GitHub は stack の merge に linear history を要求し、下段 branch に変更が入ると stack 全体の cascading rebase が必要になる場合がある。merge 前に GitHub の `Rebase stack` を実行するよう案内された場合は、その操作を完了してから進める ([GitHub requirements](https://docs.github.com/en/pull-requests/reference/stacked-pull-requests#linear-history))。

`base_ref` には `origin/<base_branch>` を使う。remote ref がない場合は fetch して取得する。stack 用の base は同一 repository の branch に限る。fork にある既存 PR の base は維持するが、fork から新規 PR を作る場合は default branch 向けの通常の PR とする。

各 step では次の値を使う。

| 用途                | 指定                                                                                                                                 |
| ------------------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| diff と crit review | `base_ref` を `crit-approval-review` に明示して渡す                                                                                  |
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

```bash
a ai pr-draft submit [--base <stack_parent_branch>]
```

既存 PR がある場合は title と body を更新する。通常フローではユーザー承認済みの場合のみ submit する。
submit 直前に共通 policy を再確認する。初回判定時から許可が続いている場合だけ、Step 3 で委任元の明示的な承認を受けた後に `a ai pr-draft submit --no-review` を使う。それ以外は通常フローに切り替え、未実施の crit と editor review を終えて人間の承認を受けてから `--no-review` なしで submit する。
`english_output` が true のときは、title と body に日本語が含まれていないこと。

`--base` の指定は「Base branch の解決」に従う。
submit の `stderr` に stack 作成の警告が出た場合、submit 自体は成功しても PR は stack に入っていない。警告の内容と出力された command を確認し、条件に合う復旧方法だけを使う。

- 下段 PR が既存 stack の途中にある警告は復旧 command を出さない。この場合は command を作らず、stack に入らなかったことを報告する。
- stack の読み取りに失敗した警告では、状態確認、stack が無い場合の作成、下段 PR が最上段の場合の追加に使う command が条件付きで出る。状態確認 command を先に実行し、その結果に応じて作成か追加のどちらか一方だけを実行する。
- `<stack_number>` などの placeholder は実際の値に置き換える。placeholder が残った command は実行しない。

復旧 command が失敗した場合は、推測した command で再試行せず、警告と出力された command を最終報告に含める。stack 作成を確認できた場合は、上記の branch config に下段 PR の番号と branch 名を保存する。

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
