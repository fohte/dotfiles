# agy でドラフトを書く flow (`role` が `private`)

SKILL.md の Step 1 と Step 4 の中身。この flow に Step 2 はない。

通常フローでは agy だけが本文を書き換える。Claude は draft を直接編集せず、ユーザーのコメントは agy に入力する。vibe mode では委任元が draft に直接コメントを書くため、委任先はコメントを追加せず、Step 4 のスクリプトで agy に反映させる。agy への入力は diff・コミット・書き方ルール・review 結果で、現在のブランチに open な Pull Request があれば既存 body も含む。

vibe mode で委任元から「draft にコメントを書いた」と返答されたら、draft に既にあるコメントをそのまま反映する。コメントを重ねて追加せず、必要なら `steps.ready-for-translation` を false に戻してから `agy-advance-draft` を実行し、agy が指摘を反映したことを確認する。成功したら draft を読み、壊れていないことを確かめて create-pr skill の Step 3 に戻り、更新した draft を委任元に再提示する。

委任元から「承認」と返答され、`english_output` が true の場合は `steps.ready-for-translation` を true にして `agy-advance-draft` を実行する。翻訳後に flag を false に戻し、title と body が英語であることを確認して create-pr skill の Step 5 に進む。

## 1. ドラフトを作成する

以下のスクリプトが diff・コミットメッセージ・書き方ルールをまとめて agy (Antigravity CLI) に渡し、ルールを満たした本文を 1 回の呼び出しで書かせて `a ai pr-draft new` に投入する。現在のブランチに open な Pull Request がある場合は、その body も渡して見出し構造と自動生成された案内文・引用を維持し、各節の本文を現在の diff とコミットに合わせて更新する。agy 側の書き方ルールの照合はこの呼び出しの中で完結する。

```bash
~/.agents/skills/create-pr/scripts/agy-write-draft
```

submit 後の PR 本文を更新するときもここから始める (submit で draft は消えている)。

失敗したら (非 0 終了) 標準エラーを確認して対応する。成功したら、draft (`~/.agents/skills/create-pr/scripts/draft-path` が出すパス) を読んで、内容が壊れていないか、diff と矛盾していないかを確かめる。問題があればユーザーに伝えたうえで Step 3 に進む。通常フローでは `a ai pr-draft review` を実行し、vibe mode では `<vibe-draft-ready>` を委任元へ送る。直すかどうかはレビューする人が判断する。

## 4. ユーザーの指示に応じた対応

以下を実行して agy に任せる。ユーザーのコメントへの対応と翻訳 (`steps.ready-for-translation: true` になった場合。`english_output` が false のときは翻訳は発生しない) のどちらが必要かは、スクリプトが frontmatter を見て自動判定する。

```bash
~/.agents/skills/create-pr/scripts/agy-advance-draft
```

`(no edits)` のときはスクリプトを実行せず、ユーザーに何を変更するか確認する。

review 後の draft はレビュー担当者の編集結果なので、diff にある内容が本文から消えていても、意図して削ったものとして扱う。

成功したら draft を読み、壊れていないことだけを確かめる。vibe mode で委任元のコメントを反映した場合は create-pr skill の Step 3 に戻り、承認後の翻訳を行った場合は Step 5 に進む。通常フローでは Step 3 に戻る。内容の過不足はレビューする人が判断するので、Step 3 の前に `agy-advance-draft` を重ねて呼ばない。スクリプトが非 0 で終了したら再実行しない。標準エラーをユーザーに伝えて、次の対応を確認する。
