---
name: crit-design-review
description: Use this skill when a delegated implementation session sends a `<crit-design-review-request>` message, either because its crit review is ready for a design check or because it fixed earlier design findings and asks for a re-check. Comment on deviations from the design in the implementer's crit review, then always post a completion comment and notify the implementer, even with zero findings.
---

# crit Design Review

委任元 (設計を持つセッション) として、委任先が人間にレビューを依頼する前に、差分のうち設計と食い違う箇所を委任先の crit review で指摘する。人間のレビューはこの review が完了 (指摘 0 件) してから始まる。

責務は設計との整合だけ。approve、コード修正、一般的なコードレビュー (人間と `self-review` の役割) はしない。

完了コメントと完了通知は指摘 0 件でも省略しない。省略すると、委任先は「指摘なし」と「まだ実行中」を区別できず、待ち続ける。

## 依頼メッセージ

委任先の `crit-approval-review` skill (「2. 設計レビューを待つ」) が形式を定義する。使うのは `crit session` (crit session id) と `Implementer session` (通知の宛先) の 2 つ。

## 手順

crit への書き込みと読み取りには、必ず `--session <crit session id>` を付ける。別の review に書き込まないため。コメントの `--author` は `design-session` にそろえる。作法は `crit:crit-cli` skill に従う。

1. 差分を読む。`~/.crit/sessions/<crit session id>.json` の `cwd` が委任先の作業ディレクトリ、`review_path` 配下の `review.json` の `base_ref` と `story` が基準と変更の概要になる。`git -C <cwd> diff <base_ref>` と `git -C <cwd> status --short` (未追跡ファイル) で差分を確認する
2. 設計と食い違う箇所を `crit comment --session <id> --author design-session <path>:<line> '<body>'` で指摘する。設計のどの記述と食い違うかを引用し、直す方向を書く。設計に書かれていないだけの実装判断は指摘しない
3. 再依頼のときは、先に自分の指摘スレッド (`crit comments --session <id> --json` の `author` が `design-session` で、完了コメントでないもの) を確認する。直っていれば `--reply-to <comment-id> --resolve` で確認内容を返信し、直っていなければ `--resolve` なしで何が違うかを追記する。`--resolve` は `design-session` のスレッドだけに使い、人間のコメントには使わない。そのうえで 2 を新しい差分に対しても行う
4. 未解決の `design-session` の指摘スレッド (path 付きのコメント) の数を N として、review 全体へ完了コメントを書く: `crit comment --session <id> --author design-session '設計レビュー完了: 指摘 N 件'`。N に完了コメントは数えない。前回の完了コメントが残っていれば、先に `--reply-to <comment-id> --resolve` で閉じる。古い件数が人間の目に未解決のまま残るのと、次回の N に混ざるのを防ぐため。N が 0 のときは、委任先が書いた「設計レビュー中」コメントも同じ方法で閉じる。人間は設計レビュー中でも crit を開けるので、完了を画面で判別できるようにするため
5. `Implementer session` に完了を通知する。`a agent peer notify --message <MESSAGE> <session_id>` で、次の形式で送る。送ったらターンを終える

```text
<crit-design-review-done>
委任元からの連絡です。
crit session: <crit session id>
設計レビュー完了: 指摘 N 件
N が 0 なら crit-approval-review の次の手順 (人間のレビュー) に進む。1 以上なら crit の未解決コメントに対応し、返信してから再依頼する。
</crit-design-review-done>
```

設計 (委任時のプロンプト、設計を書いた tq の task / page など) を参照できないときは、推測でレビューしない。完了コメントと通知に「設計を参照できず照合していない」と書いたうえで指摘 0 件として完了し、ユーザーにも伝える。

`notify` が `ended` エラーで失敗したら、宛先を推測せずユーザーに報告する。
