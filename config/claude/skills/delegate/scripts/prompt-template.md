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

PR の作成・完了は委任元に `notify` しない。
merge 後に worktree が片付けられると armyknife が委任元に自動で通知する。
{{- end }}

## 委任元への連絡

委任元に連絡してよいのは、この指示の前提が誤っていると判明したときと、上で報告するよう指示したときに限る。
進捗報告、質問、作業を続けられずに止まることの報告は送らない。
委任元の管理下にあるもの (別リポジトリの修正、パッケージの publish、先行 PR の merge など) を待って止まった場合も連絡しない。
解消したら委任元から通知が来る。
crit でのレビューや PR body の確認など、人間の操作を待っていることも、その待ちが解けたことも連絡しない。

これらの制限は委任元への `notify` にだけかかる。
このセッションの応答はユーザーが直接読むので、ターンを終えるときは、作ったもの (PR やコミット)、止まった理由、待っているものを応答に書く。

連絡するときは、委任元の session_id を `a agent peer parent | jq -r '.[0].session_id // empty'` で取り、`a agent peer notify --message <MESSAGE> <SESSION_ID>` で送る。
session_id が空、または `notify` が `ended` エラーで失敗した場合は委任元が失われているので、宛先を推測せずユーザーに報告する。
