# Designer との連携

designer がいる repo では、画面に出るものを変える実装を、対応するデザイン案が merge される前に委任しない。この手順は delegate prompt を作るときと、vibe coding の各 leaf を dispatch する前に使う。

## 対象 repo の判定

designs の `origin/HEAD` に repo のディレクトリが 1 つ以上ある場合、その repo には designer がいる。checkout の作業ツリーではなく fetch 後の `origin/HEAD` を使う。

```bash
designs=~/ghq/github.com/fohte/designs
git -C "$designs" fetch --quiet origin || true
git -C "$designs" ls-tree -d --name-only origin/HEAD "<repo>/"
```

- designs の clone が無い、またはコマンドの出力が空なら designer を使わない repo として通常どおり委任し、この reference の残りは適用しない
- fetch が失敗しても、既存の `origin/HEAD` を読めるならその内容で判定を続ける
- `origin/HEAD` が無く判定できない場合も designer を使わない repo として扱う

## 画面に出るものの判定

designs にある app の画面に出る要素を 1 つでも変えるなら「変わる」と判定する。対象には文言、キーの案内、入力欄やボタンの形、配置、色、状態表示を含む。キー操作や内部の挙動だけの変更でも、画面上の案内や表示が変わるなら「変わる」。

「変わらない」と判定する前に、変更が触る画面の app を特定し、対応する artboard を `origin/HEAD` の `<repo>/<app>/screens/project/` から列挙して読む。表示される要素を artboard と要素ごとに照合し、変更後も artboard の表示がすべて成り立ち、artboard にない表示を追加しないことを確かめる。対応する artboard が無い場合や、変更後に表示される内容が artboard に無い場合は「変わる」と判定する。

照合した artboard の repo 相対 path と「変わらない」という結論を委任 prompt の `investigated` に記録する。`goal` に「画面に出るものを変えない。変える必要が出たら実装を止め、前提の誤りとして委任元に報告する」と含める。

## 画面が変わる場合

変更後の表示が designs の `origin/HEAD` にある artboard にすでに描かれているなら、その artboard path を prompt に記録し、表示を artboard と一致させることを `goal` に書いて委任する。

変更後の表示が artboard に無い場合は、designer の案が designs に merge されるまで委任しない。案がまだ無ければ以下の「designer への依頼」に従って依頼し、merge を確認してから委任する。委任 prompt の `investigated` に design PR の URL、merge の確認結果、artboard path を記録し、`goal` を artboard と一致させる形にする。

## designer への依頼

ユーザー向けの画面や見た目のデザインが必要な場合、技術設計を行う `--kind design` の handoff セッションとは別に、対象 repo の designer セッションへ依頼する。両方を並行して進めてよい。

1. 対象を `designer <owner>/<repo>` として定め、`a agent peer list` から `work_type` が `designer` で `label` が完全一致するセッションを探す。designs の designer は repo ごとに独立したセッションで管理する。
2. 見つかった designer の `session_id` を通知先に使う。`a agent peer me | jq -r '.[0].session_id'` で依頼元の session ID を取得し、メッセージに記載して `a agent peer notify --message "<依頼内容>" <designer_session_id>` で依頼する。依頼には tq task の番号と title、決めたいデザインの内容、依頼元の session ID を含める。
3. 見つからない場合は `a agent todo add` でユーザー向け todo を作る。detail に次の起動コマンドを code block で含め、実行するコマンド行だけに `! ` を付けて owner と repo を対象に置き換える。

    ````bash
    cat <<'EOF' | a agent todo add
    {
      "title": "designer <owner>/<repo> を起動する",
      "detail": "担当 designer セッションがありません。次を実行してください:\n\n```bash\n! cd ~/ghq/github.com/fohte/designs && claude \"/designer <owner>/<repo>\"\n```"
    }
    EOF
    ````

4. designer は案の選択、canvas の確認、design PR の merge 依頼を自身のセッションでユーザーと行う。merge 依頼が必要なら designer 自身が `a agent todo add` で todo を作る。依頼元はユーザーに案の選択や canvas の確認を尋ねず、design PR の URL を共有せず、merge を依頼する proposal / todo も作らない。designer は design PR を作成したら URL を依頼元へ `a agent peer notify` で知らせ、merge されたらその旨をもう一度知らせる。デザイン確定は PR の作成やレビュー完了ではなく merge とする。merge 通知を受けたら `gh pr view <PR_URL> --json state,mergedAt` を実行し、`state` が `MERGED` かつ `mergedAt` が空でないことを確認してから実装を委任する。コマンドが失敗した場合は原因を解消して再確認し、成功応答で未 merge と確認した場合は委任せず designer から merge の通知を待つ。

`--kind design` は担当 repo の調査・技術設計を行う handoff worker の指定であり、designer を識別する値ではない。designs の designer は `work_type=designer` と `label=designer <owner>/<repo>` で識別し、依頼は `a agent peer notify` で送る。
