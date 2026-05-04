{{- $v := ds "vars" -}}

## Repo source policy

- Owned orgs — clone with `ghq get -u <org>/<repo>`, work in `~/ghq/github.com/<org>/<repo>`: - fohte
  {{- if $v.work_org }} - {{ $v.work_org }}
  {{- end }}
- Anything else (third-party repos, npm/PyPI/crates.io packages): use `opensrc path <pkg>` for shallow clone under `~/.opensrc/`.
