# 対象 repo の vibe 許可判定

`vibe_mode` は次の両方を満たす場合だけ true とする:

1. `a agent vibe status` が exit 0 である
2. 対象 repo root で `a config get repo.vibe` が exit 0 になり、boolean `true` を返す

不許可と判定してよいのは、`a agent vibe status` が `Vibe mode is not enabled.` で失敗した場合と、`a config get repo.vibe` が `false` を返した場合だけとする。session の vibe status と repo ごとの許可は別の条件なので、片方からもう片方を推測しない。

それ以外の失敗 (別のエラーメッセージ、boolean 以外の出力) は判定エラーであり、不許可ではない。session DB の障害などで一時的に失敗するだけでも、false と扱うと vibe で進めるべき作業が人間のレビュー待ちで止まる。判定エラーになったら同じコマンドを 1 回だけ再実行する。再実行もエラーなら、vibe の手順にも通常フローの人間レビューにも進まず、エラー出力を添えて前提の誤りとして委任元に報告し、ターンを終える。委任元がいなければユーザーに報告する。

vibe 専用の報告や submit の直前に両方を再確認する。初回の `vibe_mode` と再確認結果が両方 true の場合だけ続ける。許可が false になった場合は通常の人間レビューへ切り替え、`--no-review` を使わず、vibe 報告を送らない。再確認が判定エラーなら、上と同じく報告して止まる。

委任元から判定し直すよう通知されたら、その時点の判定結果を初回の `vibe_mode` として扱い直す。true なら、通常フローで待っていた crit や editor のレビューを打ち切り、vibe の手順に戻る。

## `--vibe` で起動された委任先が通常フローに切り替える場合

委任元は vibe の報告を待っているので、黙って切り替えると、委任元は人間のレビュー待ちに気付けない。初回判定が不許可だった場合と、再確認で許可がなくなった場合は、通常フローに進む前に次の形式で委任元に通知する。

```text
<vibe-fallback>
Branch: <git branch --show-current の値>
判定結果: <不許可になった条件と、そのコマンドの出力>
通常フロー (crit と editor による人間のレビュー) に切り替える。vibe で進めるべきなら、原因を直してから判定し直すよう通知してほしい。
</vibe-fallback>
```

通知した後は、委任元の返答を待たずに通常フローを進める。

## 委任元への送信手順

判定エラーや前提誤りの報告と `<vibe-fallback>` は、`a agent peer parent | jq -r '.[0].session_id // empty'` で委任元の session ID を取り、`a agent peer notify --message <MESSAGE> <SESSION_ID>` で送る。session ID が空、または `notify` が `ended` エラーで失敗した場合は、宛先を推測せずユーザーに報告する。
