{{- $v := ds "vars" -}}
{{- $fohte := or (strings.Contains "github.com/fohte/" $v.remote) (strings.Contains "github.com:fohte/" $v.remote) -}}
{{ if $fohte }}

## fohte organization context

- Gemini Code Assist is enabled for CI reviews
- Use `a ai review wait` after PR creation to wait for Gemini review
- Use `check-pr-review` skill to address review feedback
  {{ end -}}
