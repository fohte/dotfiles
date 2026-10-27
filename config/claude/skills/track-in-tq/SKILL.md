---
name: track-in-tq
description: 'Keep a piece of work tracked in tq (the user''s personal task manager) from start to close without being told each step. TRIGGER when the user hands over work that should leave a record — "tq にタスクつくっといて", "tq task つくってないとおもうから作成しといて", "tq のタスクを作成 → page に html を upload → ...", "コメントに pr 一覧となにやったかまとめる → close", "tq task に実装 pr の目的と url まとめて close", "tq page に設計まとめといて", "tq ちゃんと todo にもどして". Once triggered, stay active for the rest of the session and update the task at each milestone instead of waiting for the next instruction. SKIP for reading tq (use the tq skill), in-session TODO tracking (use TodoWrite), and GitHub issues (use the github-issue skill).'
---

# tq でタスクとして作業を追う

作業を tq のタスクとして立て、進行に合わせて状態を更新し、終わったら閉じるまでを担当する。

一度発動したらセッションの間は有効なままにする。
各ステップの指示を待たず、下記の節目に到達した時点で自分で実行する。

`tq` CLI のフラグ、`--author` の指定、長文を `--file` で渡す作法は `tq` skill を参照する。

## task owner の責務

- task owner は成果をまとめ、成果コメントを記録し、既存の完了条件を満たす場合だけ task を close する。PM が task を起票した場合も、起票者ではなく owner が行う
- 実装 delegate は成果を owner に報告し、委任元 task の成果コメントや close を行わない。owner は delegate の成果 (PR の merge や commit など) と既存の完了条件を確認し、自分の task の完了を判断する。child session の後処理は以下の close 順序に従う
- PM が task を管理する場合、owner は成果コメントへの参照、task の実際の状態、成果物・検証結果・残件の扱い、child の結果と後処理を PM に報告する。PM はこれらと owner の残作業・ユーザー判断や確認待ちの有無を確認してから owner session を閉じる。PM は task の成果コメントや close を代行しない

## 節目

| 節目                               | やること                                                                                            |
| ---------------------------------- | --------------------------------------------------------------------------------------------------- |
| 作業に着手する                     | 既存タスクを探し、使う / 作る / 作らないを判定する。使うか作るなら `tq link` でセッションを紐付ける |
| 設計・調査の結論がまとまった       | 読者向け資料が必要なら page を作成し、既存資料があれば更新する                                      |
| 最終成果や検証結果が確定・変更した | page が必要なら既存資料を最新の結果に更新し、資料がなければ作成する                                 |
| PR が merged になった              | `tq task get <id>` でチェックリスト進捗を確認し、項目に紐付かない PR も確認する                     |
| 残作業が無くなった                 | まとめコメントを書いて `complete` する                                                              |
| 残作業があるのに完了扱いになった   | `todo` に戻す                                                                                       |

## 着手する: 作るか、使うか、作らないか

`TQ_PARENT_SESSION_ID` が環境にあれば他セッションからの委任先なので、この節目ごと飛ばす。
委任先の成果物は PR 1 本で、委任元のタスクに PR がリンクされれば記録として足りる。
リンクは `create-pr` skill が `branch.<name>.x-tq-task-id` から委任元のタスクを引いて行う。

まず既存を探す。
ユーザーが手で作っていることが多く、同じ作業にタスクが 2 つあるのは 0 個より悪い。
履歴が両方に散って、どちらも記録として使えなくなる。

```bash
tq task search '<キーワード>'
```

`--status` は値を 1 つしか取れないので付けない。
`completed` の一致も判断材料になる。
同じ作業が一度完了しているなら、今回のはその続きであって新規ではない。

- 該当するタスクがある → それを使う。2 つ目を作らない
- 無く、PR や成果物が出る作業 → 作る。これは下限であって上限ではない。後から振り返る価値のある調査も作る
- 無く、痕跡が残らない作業 (質問への回答、設定 1 行の変更) → 作らない

作るのは着手時であって完了時ではない。
終わってから作ったタスクは領収書で、作業中の進捗をユーザーが見られない。

作るときは、成果物 (PR、コミット) が出るリポジトリのラベルも付ける。
cwd のリポジトリを成果物の出所と決めつけない。
cwd では調査だけして別のリポジトリに PR を出すこともあり、そう決めつけると無関係なリポジトリのラベルが付く。
成果物が cwd のリポジトリに出るなら、リポジトリ名は `git remote get-url origin` の basename から `.git` を除いたものを使う。
cwd 以外のリポジトリに出るなら、ユーザーが挙げた名前か、そのリポジトリの origin から同じように取る。
worktree では `git rev-parse --show-toplevel` が `.worktrees/<branch>` を指すことがあり、リポジトリ名の判定には使えない。

付けるラベルは、自分のリポジトリなら `dev/<リポジトリ名>`、それ以外なら `dev/oss`。
自分のリポジトリとは、origin の owner が SessionStart context の owned orgs に含まれ、かつ (origin が fork でないか、`a config get repo.standalone_fork` が `true` を返すもの)。
判定は `gh repo view "$(git remote get-url origin)" --json owner,isFork` で行う。
repo を省くと gh は `upstream` remote を優先して読むので、fork clone でも `isFork` が false になる。
origin が fork の場合、`a config get repo.standalone_fork` が `true` を返すときだけ `dev/<リポジトリ名>` にする。コマンドが失敗した場合は `true` ではない扱いとし、`dev/oss` にする。
`tq label list` に既にあれば同じものを使い、無ければ `--labels` に渡す。
未知の名前は API 側で作られるので事前作成は不要。
成果物が複数のリポジトリに出るなら、それぞれのラベルを付ける。
ラベルは 1 つに限らないが、成果物の出ないリポジトリまで探して足さない。
関連するだけのリポジトリのラベルが付くと、そのラベルで絞ったときに無関係なタスクが混ざる。
成果物の出所が決まっていない、どのリポジトリにも紐付かない (調査など)、origin が無くてリポジトリ名が取れないときはラベル無しで作り、そこで作業を止めない。
既存タスクを使う場合はこの判定をしない。
既存タスクのラベルを勝手に付け替えると、ユーザーが意図した分類を壊す。

`--parent-id` は、作るタスクが親タスクの完了条件に含まれる作業のときだけ付ける。
きっかけになったタスクや関連するタスクというだけでは付けない。
子にすると、ユーザーは親を閉じるときに完了条件外の子タスクまで確認することになる。
完了済みのタスクの子にもしない。
閉じたタスクの子は一覧で目に入りにくく、ユーザーが未着手の作業を見落とす。

作った場合も既存を使う場合も `tq link <id>` で今動いているセッションをそのタスクに紐付ける。
セッションが紐付いていること自体が着手の証拠になるので、ステータスは変更しない。
今日やると決めたものを today queue に入れるのは人間の判断であり、ここでは行わない。
`tq link` はセッションを `TQ_SESSION_ID` から特定するので、渡すのはタスク ID だけでよい。
作らないと判定したときは、この節目自体が発生しないのでリンクもしない。

## 何をどこに書くか

| 置き場所         | 書くもの                                                 |
| ---------------- | -------------------------------------------------------- |
| task description | 作業の目的や背景、完了条件など                           |
| page             | 読者が理解・判断するための設計、調査結論、説明、成果資料 |
| comment          | 完了報告。何が入ったか、どの PR か、何を判断したか       |

page は、読者が単独で理解・判断できる資料を必要とする場合に作る。資料が必要かは読者と用途で判断し、作業の長さや HTML / Markdown などの形式では決めない。短い回答など、資料を必要としない作業では page を作らない。

資料には設計や調査の結論と、判断に必要な根拠・制約・検証結果を要約して残す。観測結果や証拠の要約は、作業中の検索・試行の時系列とは分けて扱う。作業継続用の仮説、検索・試行ログ、進行状況、承認イベント、agent 間の引継ぎは page に残さず、session / `AGENT_TMPDIR` に置く。

設計が変わったら、既存の読者向け page を更新する。新しい page を作るかは、読者向け資料が必要かで判断する。
古い方針を書いたまま残った page は、page が無いより誤解を招く。
既存 page に乗る前には読む。
現状より古いことがある。

## 閉じる

`complete` してよいのは次の条件を満たすときだけ。

- `tq --author <model> task get <id>` の `githubLinks` を確認し、立てた PR が全部 merged になっている。チェックリスト項目に紐付く PR はチェックリストツリーと `checklistCompletionCount` で確認し、`completed` が `total` と同じで、すべての葉項目がチェック済みであることを確かめる。項目に紐付かない PR も `githubLinks` で状態を確認する。PR を伴わない調査だけの作業なら、この条件は無い
- 落とした項目 (「今回やらないこと」) が別タスクになっているか、ユーザーに提示済み

加えて、task owner が成果コメントを記録してから task を close する。
成果コメントには、何ができるようになったか、PR または commit などの成果物、検証結果、残件の扱いを含める。
実装 delegate child の成果と既存の完了条件を確認し、満たす場合に成果コメントと task close へ進む。child の `agent_status=done`、終了ログ、削除記録、アーカイブ時刻や終了経路の判定を追加条件にしない。
PR を伴わない作業は、commit などの成果と既存の完了条件で判断する。
owner に実施中の残作業やユーザー判断・確認待ちがある場合は task を close せず、owner session も閉じない。
実施中の残作業がある間は `complete` しない。今回やらない項目は上記の条件に従って別タスクにするかユーザーに提示する。
close 後に `tq --author <model> task get <id>` で実際の状態が `completed` になったことを確認する。
所定の merge コマンドで既に自動 close された child は後処理を繰り返さない。task が `completed` になった後も child session が残っていれば owner が通常の close で閉じる。task が pending の間は child close が拒否されるため、この順序を守る。
child session の close が拒否された場合は `--force` を使わず、owner session を `done` にせず PM 管理下なら PM に、それ以外はユーザーに報告する。
child session の後処理後、PM 管理下なら成果コメントへの参照、task の実際の状態、残作業・ユーザー確認待ちの有無、child の結果と後処理を PM に報告する。

条件を満たさない場合は `complete` せず、既に完了扱いになっているなら `tq task status <id> todo` に戻す。
残作業をまとめコメントに書いた上で完了にすると、閉じたタスクの中に未着手の作業が埋まる。

task close が拒否された場合は実際の task 状態を確認し、completed になっていなければ完了扱いにしない。
task を completed にできなければ owner session も `done` にしない。PM 管理下なら PM に、それ以外はユーザーに状態と拒否を報告する。
close を通すために完了条件・仮定・tq の親子構造・依存関係を変更しない。

残りが merge などの操作後に確認する項目だけでも、「確認できたら完了にします」と約束して待たない。未確認の完了条件を示し、操作後に成果確認と成果コメント・task close を担う task owner を明確にする。
merge 時に実装 child が自動 close されても、task owner は既存の完了条件に従って確認と成果記録を続ける。PM 管理下では owner が task の実状態と child の後処理を PM に報告し、PM は owner session の `agent_status=done` を確認してから owner session を閉じる。PM は task の成果コメントや close を代行しない。

PR 番号は下記のように tq task へのリンク化を避けた形で書く。
詳細は `tq` skill の「Cross-reference other systems by URL, not by `#number`」を参照する。

まとめコメントの型:

```md
<冒頭 1 段落: 何ができるようになったか>

## PR 一覧

| PR                                                     | 内容 |
| ------------------------------------------------------ | ---- |
| [my-app #140](https://github.com/acme/my-app/pull/140) | ...  |

## やったこと

<判断とその理由。読み手が変更の形をつかむのに要ること>

<検証結果と、残件がある場合の扱い。実施中の残作業がある間は complete しない>

<設計 page と結果がずれたなら、その差分>
```

PR が無い作業では `## PR 一覧` ごと省く。

読者向け資料を page にまとめた場合は、完了コメントから参照し、重複する詳細は書かない。
page が不要な作業では、完了コメントだけで成果が分かるようにする。
