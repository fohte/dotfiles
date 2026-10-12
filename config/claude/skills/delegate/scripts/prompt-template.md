{{- $task := ds "task" -}}
{{- $investigated := index $task "investigated" -}}
{{- $links := index $task "links" -}}
{{- $additionalContext := index $task "additionalContext" -}}

## 背景

### 目的・モチベーション

{{ strings.TrimSpace $task.purpose }}
{{- if $investigated }}

### 調査済みの内容

{{ strings.TrimSpace $investigated }}
{{- end }}
{{- if $links }}

### 参考リンク

{{- range $links }}

- {{ . }}
    {{- end }}
    {{- end }}
    {{- if $additionalContext }}

## 現状

{{ strings.TrimSpace $additionalContext }}
{{- end }}

## ゴール

{{ strings.TrimSpace $task.goal }}
{{ if eq (getenv "DELEGATE_DIRECT_COMMIT" "false") "true" }}
`commit` skill で commit し、push するところまで完了させること。PR は作成しない。

push まで終えたら委任元に完了を報告すること。
PR が残らないので、報告しない限り委任が終わったことが伝わらない。
報告には、どの委任か (委任元は複数の委任を並行させている)、push したコミット、ゴールに届かなかったものがあればその残りを含める。
{{- else }}
`commit` skill で commit し、`create-pr` skill で PR を作成するところまで完了させること。

{{- if eq (getenv "DELEGATE_VIBE" "false") "true" }}
## Vibe coding mode

この委任は vibe coding モードである。`create-pr` skill を使う前に `a agent vibe status` を実行し、終了コードが 0 の場合だけ以下の手順を適用する。コマンドが見つからない場合を含め、終了コードが 0 以外なら通常の委任として扱う。

vibe の場合は crit 承認と editor 承認を待たずに submit する。`commit` skill の self-review と CI 監視は続ける。`create-pr` skill の手順に従い、PR 本文への親レビューも draft を使って反映する。

PR の CI が green になったら、`create-pr` skill の Step 7 にある `<vibe-pr-ready>` 形式で委任元に `notify` する。チェックリスト項目 ID は現在のブランチの `branch.<name>.x-tq-checklist-item-id` から取得し、値がなければ項目 ID が見つからない前提誤りとして委任元に連絡する。

この報告後は委任元のレビューを待つ。差し戻しの `notify` を受けたら指摘に対応し、コードを変更した場合は `commit` skill に従って commit と push を行う。PR 本文の指摘は draft にコメントとして加え、選択された draft reference の Step 4 に従って反映してから `a ai pr-draft submit --no-review` を実行する。再 submit 後も CI が green になってから同じ形式で PR ready を報告する。
{{- else }}
PR の作成・完了は委任元に `notify` しない。
merge 後に worktree が片付けられると armyknife が委任元に自動で通知する。
{{- end }}
{{- end }}

## 委任元への連絡

{{- if and (eq (getenv "DELEGATE_DIRECT_COMMIT" "false") "false") (eq (getenv "DELEGATE_VIBE" "false") "true") }}
これらの連絡ルールは `a agent vibe status` が exit 0 の場合に限り適用する。0 以外なら通常の連絡ルールに戻り、前提誤り以外は `notify` しない。PR 作成・完了、進捗、質問、待ち状態を連絡せず、ターンを終える際に成果物、停止理由、待っているものをユーザーに報告する。

委任元に `notify` してよいのは、この指示の前提が誤っていると判明したときと、上記の PR ready 報告に限る。
進捗報告や質問は送らない。親レビューを待つことも連絡しない。

PR ready を報告するときと、差し戻しを反映して再報告するときは、委任元の session_id を `a agent peer parent | jq -r '.[0].session_id // empty'` で取り、`a agent peer notify --message <MESSAGE> <SESSION_ID>` で送る。
session_id が空、または `notify` が `ended` エラーで失敗した場合は委任元が失われているので、宛先を推測せずユーザーに報告する。

委任元からの差し戻しを受けたら、その指摘に対応して再度 PR ready を報告する。
{{- else }}
委任元に連絡してよいのは、この指示の前提が誤っていると判明したときと、上で報告するよう指示したときに限る。
進捗報告、質問、作業を続けられずに止まることの報告は送らない。
委任元の管理下にあるもの (別リポジトリの修正、パッケージの publish、先行 PR の merge など) を待って止まった場合も連絡しない。
解消したら委任元から通知が来る。
crit でのレビューや PR body の確認など、人間の操作を待っていることも、その待ちが解けたことも連絡しない。

これらの制限は委任元への `notify` にだけかかる。
このセッションの応答はユーザーが直接読むので、ターンを終えるときは、作ったもの (PR やコミット)、止まった理由、待っているものを応答に書く。

連絡するときは、委任元の session_id を `a agent peer parent | jq -r '.[0].session_id // empty'` で取り、`a agent peer notify --message <MESSAGE> <SESSION_ID>` で送る。
session_id が空、または `notify` が `ended` エラーで失敗した場合は委任元が失われているので、宛先を推測せずユーザーに報告する。
{{- end }}
