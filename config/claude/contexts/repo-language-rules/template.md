{{- $v := ds "vars" -}}
{{- $public := eq $v.repo.visibility "PUBLIC" -}}

## Repository language rules

{{ if $public -}}

- Code comments: write in English
- Commit messages: write in English
  {{- else -}}
- Code comments: write in Japanese
- Commit messages: write in Japanese
  {{- end }}
