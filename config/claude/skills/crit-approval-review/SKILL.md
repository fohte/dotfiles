---
name: crit-approval-review
description: crit story を作成してユーザーに差分をレビューしてもらい、指摘に対応しながら承認されるまで loop を回す。Use this skill when the commit or create-pr skill reaches its crit review step. Running this skill is one step inside the caller's workflow, never a replacement for it: committing and pushing after approval belong to the caller.
---

# crit Approval Review

差分を crit で人間にレビューしてもらい、承認を得るまでの手順。
いつ呼ぶか、承認後にどうコミット・push するかは呼び出し元の skill が決める。

## 対象の差分

crit の自動検出に任せる。feature branch では base branch から working tree まで、default branch では未コミットの変更が対象になる。
どちらも working tree を含むので、loop 中の未コミットの修正もそのまま次の round でレビューできる。

## 1. story を作成する

`crit:crit-story` skill で story を作成する。story の文章 (prologue の `title` / `overview` / `key_changes` / `risks`、各 chapter の `title` / `summary`) は**日本語で書く**。`crit story --guide` が返す guide 本文は英語だが、それは出力言語の指定ではない。

authoring では、`crit:crit-story` の例に `--no-open` がない場合も、次の形に置き換える:

```bash
crit story --guide --no-open
crit story --prep <path> --no-open
crit story --story-file <path> --no-open
crit story --refresh --story-file <path> --no-open
```

`--guide` と `--prep` は出力後に終了する。
これらは browser flow に入らないためブラウザを開かず、`--no-open` は no-op だが authoring command の契約を揃えるため付ける。
`--story-file` は保存後に review daemon を起動し、daemon が最初のタブを開く場合がある。
`--no-open` は client 側による 2 枚目のタブを抑止する。
story-file の ingest が完了したら、この段階を終了する。
bare な `crit story`、`crit story --no-spend`、`crit`、`crit review` はここで実行しない。

## 2. レビュー loop を回す

`crit:crit` skill でレビュー loop を回し、承認を待つ。委任先の無人セッションでも待つ。

ingest で daemon が最初のタブを開いた場合、レビュー loop はその daemon に接続する。
`crit:crit` の Step 1-2 に従い、初回は bare な `crit` をバックグラウンドで 1 回だけ実行する。
2 round 目以降は finish prompt が指定する次 round 用コマンドを 1 回だけ実行する。
finish prompt のコマンドを bare な `crit` に置き換えない。
`crit` と `crit review` を同じ round で併用したり、起動コマンドを再実行したりしない。
`crit story` は story を保存して終了するため、承認待ちのブロックは `crit:crit` 側が担う。

## 3. 指摘に対応する

指摘への対応は crit の loop 内で完結させる。**loop 中はコミットも push もしない** (= `commit` skill も `self-review` skill も呼ばない)。1 指摘ごとに self-review + コミットを挟むと、承認前の中間状態に重い工程を繰り返すことになる。

1. 指摘を修正する
2. `crit comment --reply-to <id>` で対応内容を返信する (作法は `crit:crit-cli` skill)
3. 修正で diff の構成が変わり story の記述とずれたなら story を作り直す (ingest 時に `--refresh --no-open`)。story の文章が依然として正しい微修正なら作り直さない
4. 次の round に進む

承認されたら呼び出し元の手順に戻る。
