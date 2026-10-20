# 対象 repo の vibe 許可判定

`vibe_mode` は次の両方を満たす場合だけ true とする:

1. `a agent vibe status` が exit 0 である
2. 対象 repo root で `a config get repo.vibe` が exit 0 になり、boolean `true` を返す

取得失敗、`false`、boolean 以外はすべて false とする。session の vibe status と repo ごとの許可は別の条件なので、片方からもう片方を推測しない。

vibe 専用の報告や submit の直前に両方を再確認する。初回の `vibe_mode` と再確認結果が両方 true の場合だけ続ける。許可が false になった場合は通常の人間レビューへ切り替え、`--no-review` を使わず、vibe 報告を送らない。
