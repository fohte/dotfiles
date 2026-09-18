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
`/commit` skill で commit し、push するところまで完了させること。PR は作成しない。

そこまで終わったら、delegate-claude skill の「委任先から委任元に連絡する場合」に従って委任元に完了を報告すること。
{{- else }}
`/commit` skill で commit し、`/create-pr` skill で PR を作成するところまで完了させること。
{{- end }}

ゴールに届かないまま作業を続けられなくなったときは、止まる前に delegate-claude skill の「委任先から委任元に連絡する場合」に従って委任元に報告すること。
