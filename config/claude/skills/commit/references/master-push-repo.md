# `is_master_push_repo` が `true` のときの手順

`SKILL.md` の `Conditions` で `is_master_push_repo` が `true` になったときだけ読む。`false` のときは `non-master-push-repo.md` を読み、このファイルは読まない。

## コミット手順

このリポジトリは default branch に直接 push する運用であり (`master-push-repos`)、コミットが squash merge で畳まれることがない。
実装完了後すぐにコミットすると、self-review 対応が別コミットとして分かれてしまう。
そのため、実装から self-review 対応までを 1 コミットにまとめる。
コミットは手順の最後に 1 回だけ行い、レビューはその前 (ステージング後、コミット前) に実行する。

1. `git status` で変更内容を確認
2. `git diff` でステージング前の差分を確認
3. `git log --oneline -5` で最近のコミットスタイルを確認
4. 変更を `git add` でステージング (**この時点ではまだコミットしない**)
5. **`self-review` skill でレビュー (条件付き必須、1 回のみ)**: `git diff --cached` を対象に実行する。省略可能な条件と、🔴 Critical / 🟡 Warning への対応方針は下記「コミット前レビュー」を参照
6. 全ての対応が完了したら、実装内容と対応の両方を含めた 1 コミットを作成 (HEREDOC を使用してフォーマットを保持):

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

7. `git status` で成功を確認
8. `git log @{u}..HEAD --oneline` で他に未 push のコミットが残っていないか確認する (upstream が未設定の場合は `git log origin/master..HEAD --oneline` で代替)
    - 今回作った 1 コミットのみ: 既に「コミット前レビュー」で `--cached` レビュー済みなので、追加レビューなしで `git push` する
    - 他にも未 push コミットが残っている場合: それらも含めて下記「push 前レビュー」を 1 回実行してから `git push` する
9. `git push` (upstream 未設定の場合は `git push -u origin HEAD`)。**「push してよいか」を尋ねて止まらない**

## コミット前レビュー

`git commit` の前に、ステージング済みの差分を `self-review` skill でレビューする。
skill は 3 観点グループ (behavior / structure / convention) の subagent を並列起動し、12 観点の統合レポートを返す。
**レビューは 1 コミットにつき 1 回だけ実行する**。
🔴 Critical / 🟡 Warning への対応で `git add` した後、レビューを再実行しない。

```bash
git diff --cached
```

省略可能なのは以下を全て満たす場合のみ:

- 変更ファイルが 1 つ以下、追加・削除合わせて 5 行以下
- 内容が typo 修正・コメント微修正・フォーマット変更・空白調整のいずれかに該当
- ロジック変更・新規ファイル作成・テスト追加・依存追加・設定変更を一切含まない

または、ユーザーが明示的に skip を指示した場合。

「小さいから」「単純だから」「明らかに問題ないから」「効率を優先したい」「変更が局所的だから」を理由とした自己判断のスキップは禁止。条件に少しでも当てはまらないなら実行する。判断に迷うなら実行する。

- 🔴 Critical: 該当コードを修正し `git add` する
- 🟡 Warning: `SKILL.md` の「🟡 Warning の判断ルール」に従い Claude が自分で判断して対応し、対応内容があれば `git add` する

**この時点ではまだコミットしない**。
全ての対応が完了したら、実装内容とレビュー対応をあわせて 1 コミットを作成する (指摘が 1 件もなければ実装内容のみで 1 コミットを作成する)。

このコミットも通常の「コミットの粒度」「コミットメッセージフォーマット」に従う。ただし self-review 指摘への対応が含まれる場合があるため:

- scope は実装本体のスコープを基本とし、指摘対応が別スコープに及ぶ場合は `, ` で区切って列挙する
- body には実装本体の action line に加えて、指摘ごとに 1 つ以上の action line を書く (`intent(<scope>): <指摘の要点と直した内容>` を指摘の数だけ)。1 つの action line に複数の指摘をまとめない
- subject は実装内容を主語にする。レビュー工程、レビュー対応そのものを主語にしない (「fix review findings」禁止のまま)

このレビューは `commit` skill の責務。

## push 前レビュー

**新規に実装をコミットする場合はこのセクションではなく上記「コミット前レビュー」を使う。**
このセクションは、既に作成済みの未 push コミットをそのまま push する場合 (例: `create-pr` skill からの呼び出し、前セッションからの持ち越し) に使う。

`git push` の前に、その push に含まれる全コミットをまとめて `self-review` skill でレビューする。
skill は 3 観点グループ (behavior / structure / convention) の subagent を並列起動し、12 観点の統合レポートを返す。
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

- 🔴 Critical: 該当コードを修正し `git add` する
- 🟡 Warning: `SKILL.md` の「🟡 Warning の判断ルール」に従い Claude が自分で判断して対応し、対応内容があれば `git add` する

**この時点ではまだコミットしない**。
全ての 🔴 Critical / 🟡 Warning への対応が完了したら、まとめて 1 コミットを作成してから push に進む (指摘が 1 件もなければコミットを作らずそのまま push する)。

このリポジトリは default branch に直接 push する運用であり (`master-push-repos`)、PR の squash merge によって履歴が畳まれることがない。
指摘のたびに修正コミットを追加すると、self-review 起因の細かい修正コミットがそのまま直線的な履歴に残り続けてしまう。
そのため、1 回の push 前レビューで見つかった全指摘への対応は、指摘同士が独立した変更に見える場合であっても 1 コミットにまとめる。

このコミットも通常の「コミットの粒度」「コミットメッセージフォーマット」に従う。ただし対象が複数の独立した指摘にまたがる場合があるため:

- scope は該当する全スコープを `, ` で区切って列挙する (例: `zsh, nvim`)
- body には**指摘ごとに 1 つ以上の action line を書く** (`intent(<scope>): <指摘の要点と直した内容>` を指摘の数だけ)。1 つの action line に複数の指摘をまとめない
- subject はレビュー工程そのものを主語にせず、実際に直した内容を書く (「fix review findings」のような書き方は禁止のまま)

このレビューは `commit` skill の責務。
`create-pr` skill から push する場合も本手順に従い、`create-pr` skill 側で `self-review` を重複して呼び出さない。
