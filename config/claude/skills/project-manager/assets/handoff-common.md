## 進め方

1. **track-in-tq skill を使う。** 上記の tq タスクを `tq link <id>` でこのセッションに紐付ける。新しいタスクは作らない (既に存在する)
2. **調査する。** 原因が未特定なら root cause を特定するまで、現状の実装がどうなっているかを自分で調べる。ここは自己完結してよい
3. **設計は plz-explain-with-crit skill でユーザーに出す。自分で確定させない。**
    - 資料の作り方と crit の往復は、すべてその skill に従う。approve されるまで往復する
    - 判断がユーザーに属するもの (何を運用に載せるか、どの外部サービスを契約するか など) も、勝手に決めず根拠付きで選択肢を示す
    - 設計に実装が含まれ、実装先リポジトリの `repo.direct_commit` が `true` でないなら、言われなくても split-into-prs skill で PR 分割まで済ませ、分割案を設計資料に含めて出す。設計と一緒に分割も approve してもらえば、委任の前にもう一度承認を待たずに済む。ユーザーが分割を指定・承認済みなら分割し直さず、その案を載せる
4. **読者向け資料が必要なら tq page にまとめる。** page の要否と内容は track-in-tq skill の「何をどこに書くか」に従い、設計・調査の結論と判断に必要な根拠を記録する。task description には書かない。PR 分割も approve されたら、handoff の「担当タスク」に記載した ID の「実装」チェックリストへ、split-into-prs の手順で Batch / PR 項目を記録する
5. **実装が必要なら delegate skill で委任する。** 自分で実装しない。委任してよいのは設計が approve され、原因が特定できてからである。1 委任 = 1 PR。approve 済みの PR 分割に従い、最初の 1 PR だけ委任して、残りは前の PR が merge されてから改めて委任する
    - 委任先の engine、model、reasoning effort は通常は選択中 profile の `delegate` type 設定を使う。ユーザーがいずれかを明示した場合だけ、対応する launcher flag で値を渡す。1 回の起動のために profile の全体選択を書き換えない
    - **delegate launcher に `--tq-task-id` で上記タスクの ID を必ず渡す。** 渡さないと委任先の PR がどのタスクにも載らない
    - PR 分割の実装チェックリストがある場合は、委任する PR に対応する葉項目 ID を delegate launcher の `--tq-checklist-item-id` に渡す。Batch 親の ID は使わない
6. **ユーザーが見ていない節目だけ引き継ぎ元 (PM セッション) に報告する。** 報告するのは、PR が merge されたとき、範囲が変わったとき、止まったとき、終わったとき。設計の approve 待ちになった、crit を開き直した、approve された、のようにユーザーが自分の画面で見ている出来事は報告しない。PM がそれをユーザーに中継し、同じ通知が二重に届いてトークンと費用の無駄になるため。`a agent peer parent | jq -r '.[0].session_id // empty'` で ID を取り、`a agent peer notify --message "<要約 + 成果物のパスや PR URL>" <session_id>` で送る。全文は貼らない

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
