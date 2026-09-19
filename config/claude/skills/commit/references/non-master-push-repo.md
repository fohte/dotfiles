# `is_master_push_repo` が `false` のときの手順

`SKILL.md` の `Conditions` で `is_master_push_repo` が `false` になったときだけ読む。`true` のときは `master-push-repo.md` を読み、このファイルは読まない。

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
8. `git push` (upstream 未設定の場合は `git push -u origin HEAD`)。**「push してよいか」を尋ねて止まらない**: commit → self-review → push は一連の継続フローであり、途中の確認は CLAUDE.md の「作業を止めない」原則に反する

## push 前レビュー

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

- 🔴 Critical: 該当コードを修正し、`git add` した上で新規コミットとして追加する (`--amend` 禁止)。
  全ての 🔴 Critical 指摘に対する修正コミットを追加し終えたら push に進む
- 🟡 Warning: `SKILL.md` の「🟡 Warning の判断ルール」に従い、Claude が自分で判断して対応する

修正コミットも通常の「コミットの粒度」(独立した変更は 1 コミットにまとめない) と「コミットメッセージフォーマット」に従う。
subject は `fix review findings` のようにレビュー工程を主語にせず、実際に直した内容を書く。

このレビューは `commit` skill の責務。
`create-pr` skill から push する場合も本手順に従い、`create-pr` skill 側で `self-review` を重複して呼び出さない。
