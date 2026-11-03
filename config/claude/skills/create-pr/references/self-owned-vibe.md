# task owner が自分で実装した場合の vibe

`vibe_mode` と `self_owned` が両方 true のときに読む。委任元への報告と承認待ちを、自分での確認に置き換える。委任元のレビューは別のエージェントが文脈を読み直すため、owner が既に持っている文脈で確かめるほうがトークンが少なく済む。

## Step 0

`vibe_mode` と同じく push だけ行い、crit レビューは省く。commit skill の self-review は通常どおり行う。

## Step 3-4: draft を自分で確かめる

`<vibe-draft-ready>` は送らない。レビュー用の subagent も起動しない。

1. draft を読み、次と照らす: tq task の description、設計 page (あれば)、この PR の葉項目の note、`scripts/render-rules` の出力、`references/draft-manual.md`
2. 直す箇所があれば `references/draft-manual.md` の Step 4 で反映する
3. 直す箇所が無くなったら、vibe policy を再確認し、許可が続いていれば `--no-review` で submit する。許可がなくなっていれば通常フローに戻る

## Step 7: CI が通ったらマージする

`<vibe-pr-ready>` は送らない。CI が green になったら、`enable-vibe-coding` skill の「When a `<vibe-pr-ready>` report arrives」の手順 2-4 を自分の PR に対して行う。VRT の差分確認、required checks の確認、breaking change のタイトルなら止まってユーザーにマージを頼むこと、マージ直前の head SHA の照合、`a gh pr-merge` でのマージが含まれる。head SHA は自分が最後に push した SHA と照合する。

マージ後は同じ skill の「After a merge」の手順 1-2 で default branch の CI を確認する。続く PR があれば、`project-manager` skill の `assets/handoff-common.md` の手順 5 に従って次のブランチを作って進める。
