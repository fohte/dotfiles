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

commit range のレビューでは、現在の branch に記録された review 済み HEAD が対象 HEAD の祖先なら、その HEAD までの commit を caller range 内から除外する。caller range より前へ範囲を広げない。merge commit は再 merge 結果との差分だけを含めるため、取り込んだ側の変更は除外され、conflict resolution はレビューされる。全 reviewer の成功後に HEAD と Claude / Codex の session ID を記録する。前回成功レビューから 1 時間以内なら reviewer ごとに session を再開し、失敗した resume は fresh session で再実行する。Codex reviewer はユーザーの指示と skills から分離した共有 `CODEX_HOME` を使い、1 時間を過ぎた rollout は Codex reviewer の起動時に整理する。対象 patch が空なら reviewer を起動せず skip し、その HEAD を記録する。`--cached` は session 再開と state 更新の対象外。

- **指摘に対応したあと、同じ差分をレビューし直さない。** 対応で差分が変われば新しい指摘が出るので、繰り返すと終わらない
- **reviewer が失敗したときの retry は 1 回まで。** それも失敗したら止めて、その reviewer を `⚠️ 未評価` として報告し、失敗出力にある原因を添える。同じ差分で 2 回続けて失敗するなら、差分が reviewer のコンテキストに収まらない場合 (`Prompt is too long`) を含め、起動し直しても結果は変わらない
- **reviewer が 1 つも結果を返さなかったら、12 観点すべてを `⚠️ 未評価` にし、Summary の件数の代わりにレビュー不能だったことと原因を書く。** 指摘 0 件と同じ出力にすると、呼び出し元がレビュー済みとして先に進む

## Backend execution

engine / model / reasoning effort は base 設定と role overlay から解決する。reviewer 固有設定を用途設定より優先し、用途設定を共通既定より優先する。各設定値の出典と実効値は reviewer 起動前に表示し、result にも保存する。Codex quota による既存 fallback は Claude へ解決し直した値を使う。

backend が返す成果物は共有 JSON schema に従う reviewer ごとの JSON です。必須の evaluation ID は reviewer-evaluation-ids.json から prompt と validator が共に読みます。集約 Markdown の見出しと日本語名は利用者向け表示であり、JSON の ID とは別の契約です。conditional reviewer の ID 集合は固定しません。

Schema validation と runner の exit 0 / 1 は schema-valid な結果が返ったことを示します。exit 0 は全 reviewer に指摘がなく、exit 1 は指摘がある結果を示しますが、どちらも要求された評価の実施までは保証しません。呼び出し元は各 evaluation の summary を読み、要求された観点を実際に確認した結果か判断してください。入力不足、resource / reference を参照できない状態、差分や対象を確認できない状態、権限制約、context 上限などで評価を実施できていない reviewer は、exit 0 / 1 でも未評価です。evaluation の一部だけが実施できていない場合も、その reviewer の初回 result 全体を集約対象から外してください。

`not-applicable` は対象を確認し、その観点が差分の構造上無関係と判断した場合に限ります。評価に必要な入力や参照がない、または制約により確認できない場合を N/A にしないでください。

reviewer 実行に失敗した場合だけ、本文を含まない診断 JSON を保存します。

- 記録項目: `run_id`、reviewer、終了コード、scope、execution mode、実効 engine / model / effort、patch と prompt の SHA-256、固定 `reason_code` と `field_path`
- 保存しない項目: prompt、diff、index、result、stdout、stderr、認証情報、manifest 本文
- 保存先: `XDG_CACHE_HOME` が未設定なら `$HOME/.cache/self-review/diagnostics`
- 権限と保持期間: directory は 0700、file は 0600。次回起動時に 7 日を超えた自分の記録だけを削除
- 手動削除: `~/.agents/skills/self-review/scripts/review-diagnostics clear`

成功した試行の診断は作りません。resume の失敗診断は fresh fallback が成功しても保持します。保存した診断の path は実行時の stderr に表示します。

呼び出し元が修復を伴う recovery round を明示的に依頼し、旧 round に失敗試行と有効評価がある場合は、通常の selector を実行せず、後述の「入力不足からの recovery round」を使ってください。

1. Resolve one immutable `<range>` from the caller (`--cached`, `@{u}..HEAD`, or another single commit range). Do not modify the index or refs until the review finishes.
   For `--cached`, snapshot the applicable index before `select-reviewers`: copy `${GIT_INDEX_FILE:-$(git rev-parse --git-path index)}` to a unique path from `mktemp "$AGENT_TMPDIR/self-review-index.XXXXXX"`, then pass `GIT_INDEX_FILE=<snapshot-path>` to `select-reviewers` and every runner invocation. Keep that snapshot unchanged until all reviewers and retries finish.
2. Create a manifest file path (`mktemp "$AGENT_TMPDIR/self-review-manifest.XXXXXX"`) and run `~/.agents/skills/self-review/scripts/select-reviewers <range> > <manifest-file>`. If it fails, launch nothing. When the cause is your own invocation (wrong working directory, or a typo in the caller's `<range>`), correct it and run it once more — no reviewer has run yet, so this does not count as a reviewer retry. Never switch to a range the caller did not give. Use the manifest file as the source of truth even if command output is missing: before step 4, run `jq -r '.status' <manifest-file>` and continue only when it returns `ready`. If it is `skipped`, do not launch reviewers and report that the range was skipped because no unreviewed changes remain. For any other status or an invalid manifest, stop and report the error. Once a ready manifest succeeds, do not call `select-reviewers` again for this review — every step below reads `<manifest-file>` instead. Its `reviewers` array is the complete launch manifest: do not add, remove, or reorder entries.
3. Carry the path `mktemp` printed as a literal string into every later step. Shell variables do not survive between tool calls, and re-deriving the path with a glob can pick up an earlier manifest from this session. Do not use `ps` or other process listings to infer progress or identify a process as yours; concurrent sessions may show another run.
4. Run `~/.agents/skills/self-review/scripts/run-external-reviewers <manifest-file>` once. In Codex, start it with `a agent bg run -- ~/.agents/skills/self-review/scripts/run-external-reviewers <manifest-file>`, then wait for the `<background-task-complete>` notification before reading its output or aggregating results. In Claude Code, use `run_in_background: true` and end the turn while waiting for the completion notification. Do not poll, sleep, or start aggregation on partial output. The script launches every reviewer in `<manifest-file>` on its own agent in parallel and returns a JSON array of results. For commit ranges, it uses the narrowed patch saved in the manifest; `--cached` omits deleted-file contents from that patch while retaining deletion metadata and file names. The exit status is `0` when every reviewer succeeded with no findings, `1` when every reviewer succeeded and at least one finding exists, `3` when any reviewer or the script itself failed (regardless of findings), and `2` / `127` for invalid input or a missing command. An exit status of `0` or `1` does not establish that every evaluation was actually performed. A reviewer run regularly outlives the foreground timeout, and being killed there loses every reviewer's result at once.
5. Never run a reviewer as a subagent, including as a fallback. Every reviewer is written for the sandbox this script puts it in, and a subagent would inherit this session's permission mode instead.
6. After the first run, mark a reviewer failed if the script reports failure or its summary says the requested evaluation could not be performed or was only partial, even when exit 0 or 1. Retry only those reviewers once by appending their names to the original manifest path (`~/.agents/skills/self-review/scripts/run-external-reviewers <manifest-file> <reviewer> [reviewer...]`). In Codex, use `a agent bg run -- ~/.agents/skills/self-review/scripts/run-external-reviewers <manifest-file> <reviewer> [reviewer...]` and wait for the `<background-task-complete>` notification. Keep every other valid reviewer result. Exclude an incomplete initial result entirely; if the retry is valid, replace that reviewer entry rather than adding a duplicate. If definition or reference contents need repair, make that repair before the single retry and use the original manifest; it consumes that retry and does not reset the limit.
7. If a manifest entry has a non-null `fallback_reason`, mention it for that reviewer in the final Summary output.

### 再試行と復旧

runner は caller が結果の意味を確認する前に、成功した実行の HEAD と session を記録します。その後の `select-reviewers` が `skipped` を返しても合格の根拠になりません。意味上の失敗が残る間は再選択せず、最初の manifest と試行回数を保持してください。

- 最初の manifest、有効な reviewer 結果、それぞれと対象差分の対応、未評価 reviewer、試行回数を引き継いでください。失敗出力の既存診断も保持し、消去しないでください。
- commit range の retry は manifest に保存された `diff` と `files` を使います。`--cached` は step 1 で作った同じ index snapshot を `GIT_INDEX_FILE` で渡し、その SHA-256 が各実行前に一致することを確認してください。初回に snapshot を使わなかった場合は、index が初回実行後に変わっていないことと対象差分との一致を確認できるときだけ再開し、確認できなければ旧結果と混ぜず再開範囲を呼び出し元へ報告してください。
- retry では manifest の definition / reference パス、targets、reviewer、agent、model、reasoning effort を変えないでください。definition / reference の本文は実行時に読み込まれるため、本文を修復した後に同じ manifest で再開できます。その他の指示本文が変わった場合、または修復に別のパス、target、reviewer、実効設定が必要な場合は、同じ manifest の retry で解決したことにせず呼び出し元へ報告してください。
- 許可された retry が残り、対象差分と修復後の定義・参照本文を確認できる場合に限り、元 manifest と未評価 reviewer を指定して再開してください。修復だけで旧結果を有効化せず、試行上限もリセットしないでください。
- retry 後も評価不能な reviewer は未評価のままにします。原因、未確定の点、必要な修復を呼び出し元へ報告し、必須レビューが完了するまで commit / push / PR を進めないでください。ユーザー提供の情報が修復に不要なら、ユーザー入力を待たずに報告してください。

## 入力不足からの recovery round

呼び出し元が修復を伴う recovery round を明示的に依頼し、旧 round に失敗試行と有効評価がある場合だけ使用します。対象は修復した reviewer 定義・参照で固定 range の未評価文書を再評価するケースです。通常の reviewer retry、任意の reset、有効評価の再実行には使いません。

1. caller の固定 range、旧 manifest、旧 round record、修復理由を渡して round を生成します。selector は保存 HEAD を参照せず、固定 range 全体から現行 YAML の Japanese targets を選びます。

    ```bash
    ~/.agents/skills/self-review/scripts/self-review-recovery-round create \
      <fixed-range> <old-manifest> <old-round-record> "<repair-reason>"
    ```

    出力された round directory をそのまま使います。`verify <round-directory>` で snapshot hash と HEAD を検証し、`manifest.json` の `.range`、`.reviewers[].targets`、`.recovery_round.input_snapshot.sha256` を確認してください。manifest は Japanese reviewer だけを含み、fixed HEAD の diff、files、各対象本文、base YAML と role overlay、definition と references の path / hash / body、resolver の実効設定と source を保存します。`round-record.json` は旧 manifest と round record の path / hash、旧失敗試行と有効評価の記録先を参照します。

2. Codex では recovery helper をバックグラウンドで起動し、完了通知を待ちます。runner を直接呼ぶと実行 ID と retry 上限が記録されないため、helper を使ってください。

    ```bash
    a agent bg run -- ~/.agents/skills/self-review/scripts/self-review-recovery-round run <round-directory>
    ```

    Claude Code では同じ helper (`~/.agents/skills/self-review/scripts/self-review-recovery-round run <round-directory>`) を `run_in_background: true` で起動し、完了通知を待つ間にターンを終えます。

    `round-record.json` の各 attempt は独立した execution ID、input / patch / prompt hash、取得できた backend session ID、runner の結果 path を結びます。recovery round は旧 session を再開せず、通常の branch review state も読み書きしません。

3. runner が exit 0 または 1 で終わったら、`round-record.json` の最新 attempt にある `output.result_path` の結果を読み、意味上の評価を記録します。exit 0 / 1 だけで評価済みとは判断しません。

    ```bash
    ~/.agents/skills/self-review/scripts/self-review-recovery-round assess \
      <round-directory> evaluated "<evaluation summary>"
    ```

    要求された評価が未実施または部分実施なら、次の assess command で `not-evaluated` と原因を記録してから、同じ round directory で helper をもう 1 回だけ実行します。runner が失敗した場合は assess を省略して helper を 1 回だけ再実行します。

    ```bash
    ~/.agents/skills/self-review/scripts/self-review-recovery-round assess \
      <round-directory> not-evaluated "<unassessed reason>"
    ```

    `not-evaluated` を記録した後、または runner が失敗した後に、同じ helper をもう 1 回だけ実行します。Codex では次を使います。

    ```bash
    a agent bg run -- ~/.agents/skills/self-review/scripts/self-review-recovery-round run <round-directory>
    ```

    Claude Code では同じ helper (`~/.agents/skills/self-review/scripts/self-review-recovery-round run <round-directory>`) を `run_in_background: true` で起動し、完了通知を待つ間にターンを終えます。

    2 回目も未評価なら `round-record.json` にその状態を残して止めます。再選択、round の作り直し、旧評価の retry はしません。結果が有効なら `evaluated` を記録し、通常の結果集約へ戻ります。

## 結果集約

`invalid` / `partial` / `empty`、evaluation が未実施と分かる summary、または retry 後も欠けている reviewer result は未評価として報告し、必須 reviewer 全員の有効な結果が揃うまで呼び出し元の `commit` / `push` / `PR` workflow を止める。

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
