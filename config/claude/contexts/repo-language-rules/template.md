{{- $v := ds "vars" -}}
{{- $lang_override := eq $v.repo_language "ja" -}}
{{- $public := and (eq $v.repo.visibility "PUBLIC") (not $lang_override) -}}

## Repository language rules

{{ if $public -}}

- Code comments: write in English
- Commit messages: write in English
  {{- else -}}
- Code comments: write in Japanese
- Commit messages: write in Japanese
  {{- end }}
