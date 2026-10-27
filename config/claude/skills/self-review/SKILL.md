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

commit range のレビューでは、現在の branch に記録された review 済み HEAD が対象 HEAD の祖先なら、その HEAD までの commit を caller range 内から除外する。caller range より前へ範囲を広げない。merge commit は再 merge 結果との差分だけを含めるため、取り込んだ側の変更は除外され、conflict resolution はレビューされる。全 reviewer の成功後に HEAD と Claude / Codex の session ID の保存を試みる。session ID や state を保存できない場合は警告し、レビュー結果は使う。state がある場合、前回成功レビューから 1 時間以内なら reviewer ごとに session を再開し、失敗した resume は fresh session で再実行する。Codex reviewer はユーザーの指示と skills から分離した共有 `CODEX_HOME` を使い、1 時間を過ぎた rollout は Codex reviewer の起動時に整理する。対象 patch が空なら reviewer を起動せず skip し、その HEAD を記録する。`--cached` は session 再開と state 更新の対象外。

- **指摘に対応したあと、同じ差分をレビューし直さない。** 対応で差分が変われば新しい指摘が出るので、繰り返すと終わらない
- **reviewer の retry は 1 回まで。** 初回 result が欠落または無効なら、その reviewer の全 evaluation を retry 対象にします。retry 後も有効な結果がない evaluation を未評価として報告し、失敗出力にある原因を添えます。有効な部分結果がある場合はその完了済み evaluation を保持し、retry が失敗しても未完了の evaluation だけを未評価として報告します。同じ差分で 2 回続けて reviewer run が失敗するなら、差分が reviewer のコンテキストに収まらない場合 (`Prompt is too long`) を含め、起動し直しても結果は変わらない
- **reviewer が 1 つも結果を返さなかったら、12 観点すべてを `⚠️ 未評価` にし、Summary の件数の代わりにレビュー不能だったことと原因を書く。** 指摘 0 件と同じ出力にすると、呼び出し元がレビュー済みとして先に進む

## Backend execution

engine / model / reasoning effort は base 設定と role overlay から解決する。reviewer 固有設定を用途設定より優先し、用途設定を共通既定より優先する。各設定値の出典と実効値は reviewer 起動前に表示し、result にも保存する。Codex quota による既存 fallback は Claude へ解決し直した値を使う。

backend が返す成果物は共有 JSON schema に従う reviewer ごとの JSON です。必須の evaluation ID は reviewer-evaluation-ids.json から prompt と validator が共に読みます。集約 Markdown の見出しと日本語名は利用者向け表示であり、JSON の ID とは別の契約です。conditional reviewer の ID 集合は固定しません。

runner は余分な field、余分または重複した evaluation ID、大小文字だけ異なる reviewer 名、空の suggestion を警告して結果を保持します。別 reviewer 名、必須 ID の欠落、空の summary、その他の構造違反は結果を拒否します。runner の exit 0 / 1 は必須項目を満たす結果が返ったことを示し、評価が実施されたことまでは保証しません。呼び出し元は各 evaluation の summary を読み、要求した観点を実際に確認した結果か判断してください。入力不足、resource / reference を参照できない状態、差分や対象を確認できない状態、権限制約、context 上限などで評価を実施できていない場合、その evaluation は未評価です。evaluation の一部だけが未実施または部分実施の場合は、その evaluation だけを未評価として、実施済みの evaluation は保持します。summary から未実施の evaluation を特定できない場合は、実施済みと確認できる evaluation だけを保持し、残りを未評価とします。

`not-applicable` は対象を確認し、その観点が差分の構造上無関係と判断した場合に限ります。評価に必要な入力や参照がない、または制約により確認できない場合を N/A にしないでください。

reviewer 実行や結果検査に失敗した場合、本文を含まない診断 JSON の保存を試みます。診断用 directory の準備、hash 算出、保存に失敗した場合も reviewer の実行と有効な結果は継続します。

- 記録項目: `run_id`、reviewer、終了コード、scope、execution mode、実効 engine / model / effort、取得できた patch と prompt の SHA-256、固定 `reason_code` と `field_path`
- 保存しない項目: prompt、diff、index、result、stdout、stderr、認証情報、manifest 本文
- 保存先: `XDG_CACHE_HOME` が未設定なら `$HOME/.cache/self-review/diagnostics`
- 権限と保持期間: directory は 0700、file は 0600。次回起動時に 7 日を超えた自分の記録だけを削除
- 手動削除: `~/.agents/skills/self-review/scripts/review-diagnostics clear`

成功した試行の診断は作りません。resume の失敗診断は保存できた場合、fresh fallback が成功しても保持します。保存した診断の path は実行時の stderr に表示します。

呼び出し元が修復を伴う recovery round を明示的に依頼し、旧 round に失敗試行と有効評価がある場合は、通常の selector を実行せず、後述の「入力不足からの recovery round」を使ってください。

1. Resolve one immutable `<range>` from the caller (`--cached`, `@{u}..HEAD`, or another single commit range). Do not modify the index or refs until the review finishes.
   For `--cached`, snapshot the applicable index before `select-reviewers`: copy `${GIT_INDEX_FILE:-$(git rev-parse --git-path index)}` to a unique path from `mktemp "$AGENT_TMPDIR/self-review-index.XXXXXX"`, then pass `GIT_INDEX_FILE=<snapshot-path>` to `select-reviewers` and every runner invocation. Keep that snapshot unchanged until all reviewers and retries finish.
2. Create a manifest file path (`mktemp "$AGENT_TMPDIR/self-review-manifest.XXXXXX"`) and run `~/.agents/skills/self-review/scripts/select-reviewers <range> > <manifest-file>`. If it fails, launch nothing. When the cause is your own invocation (wrong working directory, or a typo in the caller's `<range>`), correct it and run it once more — no reviewer has run yet, so this does not count as a reviewer retry. Never switch to a range the caller did not give. Use the manifest file as the source of truth even if command output is missing: before step 4, run `jq -r '.status' <manifest-file>` and continue only when it returns `ready`. If it is `skipped`, do not launch reviewers and report that the range was skipped because no unreviewed changes remain. For any other status or an invalid manifest, stop and report the error. Once a ready manifest succeeds, do not call `select-reviewers` again for this review — every step below reads `<manifest-file>` instead. Its `reviewers` array is the complete launch manifest: do not add, remove, or reorder entries.
3. Carry the path `mktemp` printed as a literal string into every later step. Shell variables do not survive between tool calls, and re-deriving the path with a glob can pick up an earlier manifest from this session. Do not use `ps` or other process listings to infer progress or identify a process as yours; concurrent sessions may show another run.
4. Run `~/.agents/skills/self-review/scripts/run-external-reviewers <manifest-file>` once. In Codex, start it with `a agent bg run -- ~/.agents/skills/self-review/scripts/run-external-reviewers <manifest-file>`, then wait for the `<background-task-complete>` notification before reading its output or aggregating results. In Claude Code, use `run_in_background: true` and end the turn while waiting for the completion notification. Do not poll, sleep, or start aggregation on partial output. The script launches every reviewer in `<manifest-file>` on its own agent in parallel and returns a JSON array of results. For commit ranges, it uses the narrowed patch saved in the manifest; `--cached` omits deleted-file contents from that patch while retaining deletion metadata and file names. The exit status is `0` when every reviewer succeeded with no findings, `1` when every reviewer succeeded and at least one finding exists, `3` when a reviewer backend fails, a blocking result check fails, or the script itself fails (regardless of findings), and `2` / `127` for invalid input or a missing command. Diagnostic or session state preparation and storage failures only produce warnings. An exit status of `0` or `1` does not establish that every evaluation was actually performed. A reviewer run regularly outlives the foreground timeout, and being killed there loses every reviewer's result at once.
5. Never run a reviewer as a subagent, including as a fallback. Every reviewer is written for the sandbox this script puts it in, and a subagent would inherit this session's permission mode instead.
6. After the first run, assess each requested evaluation separately. Keep every evaluation whose summary confirms it was completed, even when another evaluation by the same reviewer was not performed or was only partial. Mark only the unperformed or partial evaluations as unevaluated. If a reviewer result is missing or invalid, treat all of its requested evaluations as unevaluated. Retry a reviewer once if the script reports failure or any of its evaluations remain unevaluated. Append only those reviewers' names to the original manifest path (`~/.agents/skills/self-review/scripts/run-external-reviewers <manifest-file> <reviewer> [reviewer...]`). In Codex, use `a agent bg run -- ~/.agents/skills/self-review/scripts/run-external-reviewers <manifest-file> <reviewer> [reviewer...]` and wait for the `<background-task-complete>` notification. Keep every valid evaluation from the initial run. Use a valid retry only to fill evaluations that were unevaluated after the initial run; do not replace completed initial evaluations or aggregate an evaluation twice. Findings are stored per reviewer, so map each finding to its evaluation: for numbered evaluations, match the leading aspect number in the finding ID (`<観点番号>:<file>:<LINE>`) to the evaluation ID; for `test-philosophy`, use the evaluation summary and finding evidence to map `TEST:` findings to `test-presence` or `test-writing`; when a result has one evaluation, associate all its findings with that evaluation. Keep initial-run findings for completed evaluations and include retry findings only for evaluations that were unevaluated after the initial run and completed by the retry. Do not discard findings that cannot be mapped to an evaluation; retain them and deduplicate only by finding ID and symptom summary. Deduplicate other findings under the rules below. If the retry is invalid or still leaves evaluations unassessed, keep the completed evaluations and their findings and report only the evaluations that remain unassessed. If definition or reference contents need repair, make that repair before the single retry and use the original manifest; it consumes that retry and does not reset the limit.
7. If a manifest entry has a non-null `fallback_reason`, mention it for that reviewer in the final Summary output.

### 再試行と復旧

runner は全 reviewer の結果と必須項目を検査した後に session state の保存を試みます。state が保存されても、summary の意味上の確認を代替しません。その後の `select-reviewers` が `skipped` を返しても合格の根拠になりません。意味上の失敗が残る間は再選択せず、最初の manifest と試行回数を保持してください。

- 最初の manifest、有効な evaluation 結果とそれぞれの対象差分との対応、未評価 evaluation、未評価 evaluation を含む reviewer、試行回数を引き継いでください。失敗出力の既存診断も保持し、消去しないでください。
- commit range の retry は manifest に保存された `diff` と `files` を使います。`--cached` は step 1 で作った同じ index snapshot を `GIT_INDEX_FILE` で渡し、その SHA-256 が各実行前に一致することを確認してください。初回に snapshot を使わなかった場合は、index が初回実行後に変わっていないことと対象差分との一致を確認できるときだけ再開し、確認できなければ旧結果と混ぜず再開範囲を呼び出し元へ報告してください。
- retry では manifest の definition / reference パス、targets、reviewer、agent、model、reasoning effort を変えないでください。definition / reference の本文は実行時に読み込まれるため、本文を修復した後に同じ manifest で再開できます。その他の指示本文が変わった場合、または修復に別のパス、target、reviewer、実効設定が必要な場合は、同じ manifest の retry で解決したことにせず呼び出し元へ報告してください。
- 許可された retry が残り、対象差分と修復後の定義・参照本文を確認できる場合に限り、元 manifest と未評価 evaluation を含む reviewer を指定して再開してください。修復だけで旧結果を有効化せず、試行上限もリセットしないでください。
- retry 後も有効な結果がない evaluation は未評価のままにします。有効な評価結果が一度も返らなかった reviewer は、その reviewer の全 evaluation を未評価とします。原因、未確定の点、必要な修復を呼び出し元へ報告し、必須レビューが完了するまで commit / push / PR を進めないでください。ユーザー提供の情報が修復に不要なら、ユーザー入力を待たずに報告してください。

## 入力不足からの recovery round

呼び出し元が修復を伴う recovery round を明示的に依頼し、旧 round に失敗試行と有効評価がある場合だけ使用します。対象は修復した reviewer 定義・参照で固定 range の未評価文書を再評価するケースです。通常の reviewer retry、任意の reset、有効評価の再実行には使いません。

1. caller の固定 range、旧 manifest、旧 round record、修復理由を渡して round を生成します。selector は保存 HEAD を参照せず、固定 range 全体から指定 reviewer の targets を選びます。対象 reviewer は `japanese-writing` または `comment` で、省略時は従来どおり `japanese-writing` です。

    ```bash
    ~/.agents/skills/self-review/scripts/self-review-recovery-round create \
      <fixed-range> <old-manifest> <old-round-record> "<repair-reason>" [reviewer]
    ```

    `reviewer` は `japanese-writing` または `comment` を指定し、省略すると `japanese-writing` を選びます。修復理由には、切り詰めを示す prompt または diff の byte 数と、対象が切り詰め位置より後ろにある根拠を caller が記載してください。script はこの証拠を機械検査しません。切り詰めの証拠がある評価は、summary が完了を示していても未評価として扱います。

    出力された round directory をそのまま使います。`verify <round-directory>` で snapshot hash と HEAD を検証し、`manifest.json` の `.range`、`.reviewers[].targets`、`.recovery_round.input_snapshot.sha256` を確認してください。manifest は指定した reviewer だけを含み、fixed HEAD の diff、files、各対象本文、base YAML と role overlay、definition と references の path / hash / body、resolver の実効設定と source を保存します。`round-record.json` は旧 manifest と round record の path / hash、旧失敗試行と有効評価の記録先を参照します。既存の Japanese round は manifest を変更せず verify できます。

2. Codex では recovery helper をバックグラウンドで起動し、完了通知を待ちます。runner を直接呼ぶと実行 ID と retry 上限が記録されないため、helper を使ってください。

    ```bash
    a agent bg run -- ~/.agents/skills/self-review/scripts/self-review-recovery-round run <round-directory>
    ```

    Claude Code では同じ helper (`~/.agents/skills/self-review/scripts/self-review-recovery-round run <round-directory>`) を `run_in_background: true` で起動し、完了通知を待つ間にターンを終えます。

    `round-record.json` の各 attempt は独立した execution ID、input / patch / prompt hash、取得できた backend session ID、runner の結果 path を結びます。recovery round は旧 session を再開せず、通常の branch review state も読み書きしません。

3. runner が exit 0 または 1 で終わったら、`round-record.json` の最新 attempt にある `output.result_path` の結果を読み、要求された evaluation ごとに実施状況を確認します。exit 0 / 1 だけで評価済みとは判断しません。すべての evaluation が実施済みなら `evaluated` を記録します。未実施または部分実施の evaluation があれば、それだけを理由に `not-evaluated` を記録し、reason には未評価の evaluation と理由を書きます。`round-record.json` の attempt 単位の状態は実行全体の完了を示します。結果ファイル内で実施済みと確認できた evaluation を無効にはしません。

    ```bash
    ~/.agents/skills/self-review/scripts/self-review-recovery-round assess \
      <round-directory> evaluated "<evaluation summary>"
    ```

    要求された評価が未実施または部分実施なら、次の assess command で `not-evaluated` と未評価の evaluation を記録してから、同じ round directory で helper をもう 1 回だけ実行します。runner が失敗した場合は assess を省略して helper を 1 回だけ再実行します。

    ```bash
    ~/.agents/skills/self-review/scripts/self-review-recovery-round assess \
      <round-directory> not-evaluated "<unassessed reason>"
    ```

    `not-evaluated` を記録した後、または runner が失敗した後に、同じ helper をもう 1 回だけ実行します。旧 round と recovery round の各 attempt で実施済みの evaluation とその findings を保持し、retry は未評価だった evaluation とその findings を補うために使います。同じ evaluation と finding は一度だけ集約します。Codex では次を使います。

    ```bash
    a agent bg run -- ~/.agents/skills/self-review/scripts/self-review-recovery-round run <round-directory>
    ```

    Claude Code では同じ helper (`~/.agents/skills/self-review/scripts/self-review-recovery-round run <round-directory>`) を `run_in_background: true` で起動し、完了通知を待つ間にターンを終えます。

    2 回目も未評価の evaluation が残る場合は、その attempt に `not-evaluated` を記録して `round-record.json` の状態を残し、実施済み evaluation とその findings を保持したまま止めます。未評価の evaluation だけを未評価として報告します。再選択、round の作り直し、旧評価の retry はしません。残っていた evaluation がすべて実施済みなら `evaluated` を記録し、保持した結果と合わせて通常の結果集約へ戻ります。

## 結果集約

有効な evaluation result が一度も返らなかった reviewer は、その reviewer の全 evaluation を未評価として報告します。`invalid` / `empty`、必須 ID の欠落、空の summary は結果を無効とし、`partial` または未実施・部分実施と分かる summary は未実施の evaluation だけを未評価として報告します。実施済みの evaluation とその findings は保持し、summary から未実施の evaluation を特定できない場合は実施済みと確認できる evaluation だけを保持して残りを未評価とします。形式上の警告や診断・session state の保存失敗だけでは評価を未実施にしません。

findings は schema 上 reviewer 単位の配列です。初回 result の実施済み evaluation に属する findings を保持し、retry result からは初回で未評価だった evaluation のうち retry で補えた evaluation に属する findings だけを追加します。対応付けには手順 6 の規則を使います。

retry 後も欠けている evaluation を未評価として報告し、必須 reviewer 全員の全 evaluation に有効な結果が揃うまで呼び出し元の `commit` / `push` / `PR` workflow を止める。

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
- `⚠️ 未評価`: retry 後も未実施・部分実施と確認された evaluation。有効な結果が一度も返らなかった reviewer は全 evaluation が該当する
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
