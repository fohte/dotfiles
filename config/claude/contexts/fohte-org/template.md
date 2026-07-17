{{- $v := ds "vars" -}}
{{- $fohte := or (strings.Contains "github.com/fohte/" $v.remote) (strings.Contains "github.com:fohte/" $v.remote) -}}
{{- if $fohte -}}

## fohte organization context

- No automated PR review bot is configured — `create-pr` and `check-pr-review` treat this org as no-op for review-waiting
  {{- if $v.repo_note }}

## Obsidian notes for {{ $v.repo_name }}

<details>
<summary>notes/inbox/{{ $v.repo_name }}.md</summary>

{{ $v.repo_note }}

</details>

- Use `/wiki-local` skill to read/write related notes or explore linked notes in the vault
  {{- end }}
  {{- end }}
