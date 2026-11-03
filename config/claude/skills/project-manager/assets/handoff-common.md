## 進め方

1. **track-in-tq skill を使う。** 上記の tq タスクを `tq link <id>` でこのセッションに紐付ける。新しいタスクは作らない (既に存在する)
2. **調査する。** 原因が未特定なら root cause を特定するまで、現状の実装がどうなっているかを自分で調べる。ここは自己完結してよい
3. **設計の判断を仕分ける。** ゴールが明確なら、仕様の詳細 (UI の見た目や操作、最初にどこまで作るか、処理の共通化など) は自分で決め、理由を PR 本文の Design decisions に残す。人間の承認を待つと、そのぶん作業が止まり、読み直しのトークンも増えるため。次のどれかに当たる論点だけを、plz-explain-with-crit skill でユーザーに出す。資料の作り方と crit の往復はその skill に従い、approve されるまで往復する
    - 権限やセキュリティの範囲を変える
    - お金や個人アカウントが絡む (有料サービスの契約、アカウントやトークンの扱い)
    - ユーザーが過去に下した決定を覆す
    - 消すと戻せない操作をする
    - ユーザーが手で確かめないと決まらない (実機での操作感など)
    - handoff やタスクに、ユーザーが決めると書いてある
    - 実装先リポジトリで `a config get repo.vibe` が `true` を返さない。この場合は今までどおり、設計全体と、手順 4 で PR 分割をする場合はその分割案を、crit で approve してもらってから実装に入る
4. **PR 分割と記録。** 実装先リポジトリの `repo.direct_commit` が `true` でないなら、split-into-prs skill で PR 分割を決め、handoff の「担当タスク」に記載した ID の「実装」チェックリストへ記録する。手順 3 で crit に出す論点が無ければ、分割は承認を待たずに記録する。読者向け資料が必要なら、track-in-tq skill の「何をどこに書くか」に従って tq page にまとめる。task description には書かない
5. **実装は自分でする。** delegate skill で委任しない。委任先が文脈を読み直す分と、そのレビューの分だけトークンが増えるため。原因が特定でき、手順 3 で crit に出した論点が approve されてから着手する
    - PM が `--worktree` で起動していれば、このセッションは `.worktrees/<name>` の worktree にいて、最初のブランチには tq タスクの ID が記録されている。default branch のチェックアウトにいる場合は実装を始めず、worktree で起動し直すよう PM に報告する
    - PR は分割に従って 1 本ずつ作る。2 本目以降は `git switch -c fohte/<name> <base>` で新しいブランチを作る。`<base>` は、前の PR がマージ済みなら `origin/<default branch>`、未マージで依存しているなら前の PR のブランチにする。`<name>` は delegate skill のブランチ名の規則 (ハイフン区切り、`/` を含めない) に従う。新しいブランチでは `git config branch.<branch>.x-tq-task-id <task-id>` と、その PR の葉項目の `x-tq-checklist-item-id` を記録する。create-pr skill が PR を tq に紐付けるのに使う
    - PR の作成は create-pr skill に従う。vibe の場合は、その skill の「task owner が自分で実装した場合」の手順で、自分で draft を確かめて submit し、CI が通ったらマージまで進める
6. **ユーザーが見ていない節目だけ引き継ぎ元 (PM セッション) に報告する。** 報告するのは、PR が merge されたとき、範囲が変わったとき、止まったとき、終わったとき。手順 3 で自分で決めた判断も、PR 本文に残るので報告しない。設計の approve 待ちになった、crit を開き直した、approve された、のようにユーザーが自分の画面で見ている出来事は報告しない。PM がそれをユーザーに中継し、同じ通知が二重に届いてトークンと費用の無駄になるため。`a agent peer parent | jq -r '.[0].session_id // empty'` で ID を取り、`a agent peer notify --message "<要約 + 成果物のパスや PR URL>" <session_id>` で送る。全文は貼らない

## task の成果記録と close

- このセッションが担当 task の owner である。task を起票した PM は成果コメントや task close を代行しない
- owner は実装 delegate child の成果と track-in-tq skill の既存完了条件を確認し、条件を満たす場合に成果コメントを記録して task を close する。child の `agent_status=done`、終了ログ、削除記録、アーカイブ時刻や終了経路の判定を追加条件にしない。成果コメントには成果物 (PR または commit)、検証結果、残件の扱いを含める。実施中の残作業があれば task を close しない
- 所定の merge コマンドが実装 child を自動 close した場合は、owner はその後処理を繰り返さない。task の実際の状態が `completed` になった後も child session が残っていれば、owner は通常の close で閉じる。task が pending の間は child close が拒否されるため、この順序を守る。拒否されたら `--force` を使わず owner session を `done` にせず PM に報告する
- owner はコメントへの参照、task の実際の状態、残作業・ユーザー確認待ちの有無、実装 delegate children の結果と必要な後処理を PM に報告する
- PM は報告と tq の実状態が `completed` であることを確認し、残作業やユーザー判断・確認待ちがなく、children の後処理が済み、owner session が `done` の場合だけ owner session を閉じる。条件を確認できなければ task と owner session を閉じない
- close のために完了条件・仮定・tq の親子構造・依存関係を変更しない。session close が拒否された場合は `--force` で回避しない

## 全体の文脈

<プログラム全体の目標と、全体像・完了条件が書かれた場所 (起点タスクの page など)>

**起点タスク (tq #<起点タスク番号>) の完了条件・仮定は書き換えない。** 狭める必要が出たら、狭めることをユーザーに明示して合意を取る。**tq の親子構造や依存関係も勝手に変えない。**

<現状: どこまで終わっていて、何が残っているか>

このセッションは PM セッションから切り出された作業セッションで、他の残タスクも並行して別セッションに配られている。自分の担当タスク以外に手を出さない。
