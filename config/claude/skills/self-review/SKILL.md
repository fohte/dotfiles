---
name: self-review
description: 差分を複数の専門 reviewer へ分割して並列レビューし、12 観点の統合レポートを返す。Use this skill when a diff range has already been chosen for review — because the commit skill reached its review step, or because the user asked for a review directly. Running this skill is one step inside the caller's workflow, never a replacement for it.
---

# Self Review

差分レビューを専門 reviewer へ分割して並列実行し、結果を統合する。
reviewer の選択順、agent、trigger、reference は `reviewers.yaml` を唯一の定義とする。

## 1 回の呼び出しで 1 回だけレビューする

レビューが十分かどうかを判定するのは呼び出し元であり、この skill ではない。
自分で次の round を始めると、呼び出し元の手順に戻れなくなる。

- **指摘に対応したあと、同じ差分をレビューし直さない。** 対応で差分が変われば新しい指摘が出るので、繰り返すと終わらない
- **reviewer が失敗したときの retry は 1 回まで。** それも失敗したら止めて、その reviewer を `⚠️ 未評価` として報告する。同じ差分で 2 回続けて失敗するのは差分ではなく実行環境側の問題なので、起動し直しても結果は変わらない
- **reviewer が 1 つも結果を返さなかったら、12 観点すべてを `⚠️ 未評価` にし、Summary の件数の代わりにレビュー不能だったことと原因を書く。** 指摘 0 件と同じ出力にすると、呼び出し元がレビュー済みとして先に進む

## Backend execution

1. Resolve one immutable `<range>` from the caller (`--cached`, `@{u}..HEAD`, or another single commit range). Do not modify the index or refs until the review finishes.
2. Create a manifest file path (`mktemp /tmp/self-review-manifest.XXXXXX`) and run `~/.agents/skills/self-review/scripts/select-reviewers <range> > <manifest-file>`. If it fails, launch nothing. When the cause is your own invocation (wrong working directory, or a typo in the caller's `<range>`), correct it and run it once more — no reviewer has run yet, so this does not count as a reviewer retry. Never switch to a range the caller did not give. If that also fails, or the cause is anything else, stop and report the error. Once it succeeds, do not call `select-reviewers` again for this review — every step below reads `<manifest-file>` instead. Its `reviewers` array is the complete launch manifest: do not add, remove, or reorder entries.
3. Carry the path `mktemp` printed as a literal string into every later step. Shell variables do not survive between tool calls, and concurrent sessions write their manifests to the same directory under the same name pattern, so re-deriving the path with a glob or `ls -t` picks up whichever session wrote last and reviews someone else's diff.
4. Run `~/.agents/skills/self-review/scripts/run-external-reviewers <manifest-file>` once, with `run_in_background: true`. It launches every reviewer in `<manifest-file>` on its own agent in parallel and returns a JSON array of results. The exit status is `0` when every reviewer succeeded with no findings, `1` when every reviewer succeeded and at least one finding exists, `3` when any reviewer or the script itself failed (regardless of findings), and `2` / `127` for invalid input or a missing command. A reviewer run regularly outlives the foreground timeout, and being killed there loses every reviewer's result at once. End the turn and wait for the completion notification — do not poll, sleep, or start the aggregation on partial output.
5. Never run a reviewer as a subagent, including as a fallback. Every reviewer is written for the sandbox this script puts it in, and a subagent would inherit this session's permission mode instead.
6. On exit status `3`, retry once with the failed reviewers' names appended (`run-external-reviewers <manifest-file> <reviewer> [reviewer...]`), which re-runs only those. The first run still printed the reviewers that succeeded, so take the union of both runs' results and mark unevaluated only the reviewers missing from it.
7. If a manifest entry has a non-null `fallback_reason`, mention it for that reviewer in the final Summary output.

## 結果集約

通し番号を持つ 12 観点を番号順に並べ、番号を持たない base reviewer (test-philosophy) の評価をその後へ、起動した conditional reviewer の評価をさらにその後へ追加する。
未起動の conditional reviewer は出力しない。

### Dedup ルール

指摘 ID と症状要約を key に以下を適用する:

1. 同一 file:line かつ同一 issue は 1 件にマージし、両方の reviewer 名を記録する
2. 同一 file:line でも異なる issue は別件として残し、`co-located` を付ける
3. 同一 issue でも location が異なる場合は別件として残し、互いを cross-reference する
4. severity が異なる場合は高い方を採用する

## 出力形式

以下の 3 セクションをこの順序で必ず出す。
指摘がなくても全 header を出す。

### 1. 観点別評価

base reviewer の観点を全件出力し、各項目に以下のいずれかを付ける:

- `✅`: 壊れる可能性を検討した上で問題なし
- `⚠️ N/A`: この diff に構造上関係しない。理由を 1 行で付ける
- `⚠️ 未評価`: reviewer が retry 後も失敗した
- `🔴` / `🟡`: 指摘あり。複数ある場合は最重要 marker と総件数を併記する

```text
## 観点別評価

1. 正しさ: <marker> <summary>
2. セキュリティ: <marker> <summary>
3. パフォーマンス: <marker> <summary>
4. 並行性: <marker> <summary>
5. エラーハンドリング: <marker> <summary>
6. 互換性: <marker> <summary>
7. 可観測性: <marker> <summary>
8. 保守性: <marker> <summary>
9. テスト容易性: <marker> <summary>
10. ドキュメント整合性: <marker> <summary>
11. プロジェクト規約遵守: <marker> <summary>
12. リファクタリング機会: <marker> <summary>

- テストの有無: <marker> <summary>
- テストの書き方: <marker> <summary>
```

起動した conditional reviewer の評価は manifest / result の reviewer 順で続ける。

### 2. 指摘詳細

`🔴` / `🟡` の指摘を重要度順に並べる。
指摘がなければ `指摘なし` と出力する。
同じ症状が多数ある場合は代表的な 1-2 件に絞り、残りの件数を注記する。

### 3. サマリ

```text
## Summary

- Critical: <count>
- Warning: <count>
- Files reviewed: <count>
```
