---
name: crit-approval-review
description: crit story を作成してユーザーに差分をレビューしてもらい、指摘に対応しながら承認されるまで loop を回す。Use this skill when the commit or create-pr skill reaches its crit review step. Running this skill is one step inside the caller's workflow, never a replacement for it: committing and pushing after approval belong to the caller.
---

# crit Approval Review

差分を crit で人間にレビューしてもらい、承認を得るまでの手順。
いつ呼ぶか、承認後にどうコミット・push するかは呼び出し元の skill が決める。

委任元がいるセッションでは、人間のレビューの前に委任元の設計レビュー (`crit-design-review` skill) を挟む。設計との食い違いは人間に回す前に解消し、人間は設計と整合した差分だけを見る。

## 対象の差分

呼び出し元から base ref が渡された場合は、その ref を crit に明示して使う。指定がない場合は crit の自動検出に任せる。feature branch では base branch から working tree まで、default branch では未コミットの変更が対象になる。
どちらも working tree を含むので、loop 中の未コミットの修正もそのまま次の round でレビューできる。

## 1. story を作成する

`crit:crit-story` skill で story を作成する。story の文章 (prologue の `title` / `overview` / `key_changes` / `risks`、各 chapter の `title` / `summary`) は**日本語で書く**。`crit story --guide` が返す guide 本文は英語だが、それは出力言語の指定ではない。

作成前に `a agent peer parent | jq -r '.[0].session_id // empty'` で委任元の session_id を取る。空なら設計レビューを飛ばし (「2. 設計レビューを待つ」は実行しない)、overview の冒頭に「設計レビューなし: 委任元がいない」と書く。

authoring では、`crit:crit-story` の例に `--no-open` がない場合も、次の形に置き換える:

```bash
crit story --guide --no-open
crit story --prep <path> [--base-branch <base_ref>] --no-open
crit story --story-file <path> [--base-branch <base_ref>] --no-open
crit story --refresh --story-file <path> [--base-branch <base_ref>] --no-open
```

呼び出し元から `base_ref` が渡された場合は、prep、story の ingest、refresh のすべてに同じ `--base-branch <base_ref>` を指定する。create-pr skill は stack 対象 branch の remote ref (`origin/<base_branch>`) を渡す。

`--guide` と `--prep` は出力後に終了する。
これらは browser flow に入らないためブラウザを開かず、`--no-open` は no-op だが authoring command の契約を揃えるため付ける。
`--story-file` は保存後に review daemon を起動し、daemon が最初のタブを開く場合がある。
`--no-open` は client 側による 2 枚目のタブを抑止する。
story-file の ingest が完了したら、この段階を終了する。
bare な `crit story`、`crit story --no-spend`、`crit`、`crit review` はここで実行しない。

## 2. 設計レビューを待つ

委任元がいる場合だけ行う。完了するまで `crit-approval` を起動しない。

1. crit session id を取る: `crit status --json | jq -r '.sessions[].id'`。複数あれば `~/.crit/sessions/<id>.json` の `cwd` が現在のディレクトリのもの
2. review 全体へ「設計レビュー中」のコメントを書く: `crit comment --session <id> --author 'Claude Code' '設計レビュー中: 人間のレビューはまだ始まっていない'`。人間は設計レビュー中でも crit を開けるので、完了前であることが画面で分かるようにする。指摘 0 件で完了するときに、委任元がこのコメントを resolve する
3. `a agent peer notify --message <MESSAGE> <委任元の session_id>` で依頼する。`Implementer session` は `a agent peer me | jq -r '.[0].session_id'` で取る

    ```text
    <crit-design-review-request>
    crit session: <crit session id>
    Implementer session: <自分の session_id>
    crit-design-review skill の手順に従う。
    </crit-design-review-request>
    ```

4. `a agent status set wait "design review of <repo.name> diff"` を実行してターンを終える。`sleep` などで turn 内に留まらない。完了通知 `<crit-design-review-done>` が新しい turn として届くまで、次に進まない
5. 通知の指摘が 0 件なら「3. レビュー loop を回す」に進む。1 件以上なら、「4. 指摘に対応する」と同じ要領で修正して返信し (コミットも push もしない)、手順 3 から繰り返す (手順 2 のコメントは残したままにし、書き直さない)。指摘 0 件で完了するまで人間のレビューを始めない

`notify` が `ended` エラーで失敗したら委任元が失われている。設計レビューを飛ばし、手順 2 のコメントを `--reply-to <comment-id> --resolve` で閉じ (id は `crit comments --session <id> --json` で探す)、story を `--refresh --story-file <path> [--base-branch <base_ref>] --no-open` で作り直して overview の冒頭に「設計レビューなし: 委任元が終了している」と書き、「3. レビュー loop を回す」に進む。

## 3. レビュー loop を回す

`crit:crit` skill でレビュー loop を回し、承認を待つ。委任先の無人セッションでも待つ。

ingest で daemon が最初のタブを開いた場合、レビュー loop はその daemon に接続する。
`crit:crit` の Step 1-2 に従い、初回は `crit-approval` をバックグラウンドで 1 回だけ実行する。
Codex では `a agent bg run -- crit-approval [args...]` を使い、完了通知まで待つ。
2 round 目以降は finish prompt が指定する次 round 用コマンドを 1 回だけ実行し、先頭の `crit` を `crit-approval` に置き換える。
`crit-approval` と `crit review` を同じ round で併用したり、起動コマンドを再実行したりしない。
`crit story` は story を保存して終了するため、承認待ちのブロックは `crit:crit` 側が担う。

wrapper は `approved: true` の出力を検出すると、その時点の `HEAD` を Git metadata に記録する。

## 4. 指摘に対応する

指摘への対応は crit の loop 内で完結させる。**loop 中はコミットも push もしない** (= `commit` skill も `self-review` skill も呼ばない)。1 指摘ごとに self-review + コミットを挟むと、承認前の中間状態に重い工程を繰り返すことになる。

1. 指摘を修正する
2. `crit comment --reply-to <id>` で対応内容を返信する (作法は `crit:crit-cli` skill)
3. 修正で story の記述とずれたなら story を作り直す (ingest 時に `--refresh --no-open`)。ファイルの追加・削除・rename や hunk の増減があれば、文章が正しくても `hunk_refs` が古い hunk を指して chapter が空になるため必ず作り直す。既存 hunk 内だけの微修正で文章も正しいなら作り直さない
4. 次の round に進む

承認されたら wrapper が記録を保存したことを前提に、呼び出し元の手順に戻る。
