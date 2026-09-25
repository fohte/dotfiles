# agy でドラフトを書く flow (`role` が `private`)

SKILL.md の Step 1 と Step 4 の中身。この flow に Step 2 はない。

## 1. ドラフトを作成する

Claude は本文を読まない。以下のスクリプトが diff・コミットメッセージ・書き方ルールをまとめて agy (Antigravity CLI) に渡し、ルールを満たした本文を 1 回の呼び出しで書かせて `a ai pr-draft new` に投入する。セルフレビューはこの中で完結しており、独立した工程はない。

```bash
~/.agents/skills/create-pr/scripts/agy-write-draft
```

失敗したら (非 0 終了) 標準エラーを確認して対応する。成功したら Step 2 はないので、そのまま Step 3 (`a ai pr-draft review`) に進む。

## 4. ユーザーの指示に応じた対応

対応は以下を実行して agy に任せる。Claude が diff から読むのは `steps` の行だけでよく、本文コメントの解釈はスクリプトの責務。ユーザーのコメントへの対応と、翻訳 (`steps.ready-for-translation: true` になった場合。`english_output` が false のときは翻訳は発生しない) のどちらが必要かもスクリプトが frontmatter を見て自動判定する。

```bash
~/.agents/skills/create-pr/scripts/agy-advance-draft
```

`(no edits)` のときだけは agy に渡すものがないので、ユーザーに何を変更するか確認する。

スクリプトが非 0 で終了したら再実行しない。標準エラーをユーザーに伝えて、次の対応を確認する。
