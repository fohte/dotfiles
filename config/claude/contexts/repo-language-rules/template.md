{{- $v := ds "vars" -}}
{{- $lang_override := eq $v.repo_language "ja" -}}
{{- $visibility := "" -}}
{{- if test.IsKind "map" $v.repo }}{{ $visibility = $v.repo.visibility }}{{ end -}}
{{- $public := and (eq $visibility "PUBLIC") (not $lang_override) -}}

## Repository language rules

{{ if $public -}}

- Code comments: write in English
- Commit messages: write in English
  {{- else -}}
- Code comments: write in Japanese
- Commit messages: write in Japanese
  {{- end }}
