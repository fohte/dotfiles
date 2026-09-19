{{- $v := ds "vars" -}}
{{- if $v.vault_path }}

## Obsidian vault

- obsidian-v2 vault path: {{ $v.vault_path }}
  {{- end }}
