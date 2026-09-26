# agy でドラフトを書く flow (`role` が `private`)

SKILL.md の Step 1 と Step 4 の中身。この flow に Step 2 はない。

本文を書き換えるのは agy だけ。Claude が draft ファイルを直接編集したり、コメントを書き込んだりはしない。agy に伝えたいことがあれば、スクリプトの第 1 引数に指示を渡す。

## 1. ドラフトを作成する

以下のスクリプトが diff・コミットメッセージ・書き方ルールをまとめて agy (Antigravity CLI) に渡し、ルールを満たした本文を 1 回の呼び出しで書かせて `a ai pr-draft new` に投入する。agy 側の書き方ルールの照合はこの呼び出しの中で完結する。

```bash
~/.agents/skills/create-pr/scripts/agy-write-draft ['<agy への追加指示>']
```

submit 後の PR 本文を更新するときもここから始める (submit で draft は消えている)。

失敗したら (非 0 終了) 標準エラーを確認して対応する。成功したら、draft (`~/.agents/skills/create-pr/scripts/draft-path` が出すパス) を読んで、内容が壊れていないか、diff と矛盾していないかを確かめる。問題があれば、引数で指示を渡して `agy-advance-draft` を実行し、もう一度確かめる。問題がなければ Step 3 (`a ai pr-draft review`) に進む。

## 4. ユーザーの指示に応じた対応

以下を実行して agy に任せる。ユーザーのコメントへの対応と翻訳 (`steps.ready-for-translation: true` になった場合。`english_output` が false のときは翻訳は発生しない) のどちらが必要かは、スクリプトが frontmatter を見て自動判定する。

```bash
~/.agents/skills/create-pr/scripts/agy-advance-draft ['<agy への追加指示>']
```

`(no edits)` で、Claude からも指示がないときは、ユーザーに何を変更するか確認する。

成功したら、Step 1 と同じく draft を読んで確かめてから Step 3 に戻る。スクリプトが非 0 で終了したら再実行しない。標準エラーをユーザーに伝えて、次の対応を確認する。
