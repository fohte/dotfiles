{{- $v := ds "vars" -}}

## Repo source policy

Owned orgs — clone with `ghq get -u <org>/<repo>`, work in `~/ghq/github.com/<org>/<repo>`:
{{ range ($v.owned_orgs | strings.Split "\n") }}
- {{ . }}{{ end }}

Anything else (third-party repos, npm/PyPI/crates.io packages): use `opensrc path <pkg>` for shallow clone under `~/.opensrc/`.
