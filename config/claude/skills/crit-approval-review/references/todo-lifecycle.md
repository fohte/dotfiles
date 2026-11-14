# crit 待機中の todo

`crit` のユーザー待ち round では、この手順を各 skill の round 固有の完了条件と合わせて使う。

## 登録と再利用

todo はユーザーが次にする作業を表す。タイトルには対象だけを書き、「crit で」などの表示場所や手段は含めない。詳細 (`detail`) は付けない。

新しい round の直前に、対象に合わせた `todo_title` を指定して登録し、出力された sequence number を控える。同じ round の再開時に前回の todo が pending なら、それを再利用して新しい todo を登録しない。

```bash
todo_title="レビュー対象の差分を確認する"
jq -n --arg title "$todo_title" '{title: $title}' | a agent todo add
```

## 完了と取り下げ

todo の Mark done / Reject 通知 (`<armyknife-todo-completed>` / `<armyknife-todo-rejected>`) が届いても、crit の round が終わるまでは待ち続ける。Reject にコメントがあればその指示に従う。todo の処理結果を crit の承認や round 結果として扱わない。

各 skill が定める正常なユーザー応答を含む round 結果が返ったら、その内容を処理する前に `a agent todo withdraw <SEQ>` で todo を取り下げる。すでに Mark done / Reject で処理済みの場合に `todo is already resolved or does not exist` が返ったら無視する。

正常な round 結果が返らなかった場合は todo を残す。同じ round を再開するときはその pending todo を再利用する。
