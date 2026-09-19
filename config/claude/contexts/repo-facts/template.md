{{- $v := ds "vars" -}}

## Repository facts

{{ if test.IsKind "map" $v.repo -}}

- repo.owner: {{ $v.repo.owner.login }}
- repo.name: {{ $v.repo.name }}
- repo.visibility: {{ $v.repo.visibility }}
  {{ end -}}
- repo.language: {{ $v.repo_language | default "unset" }}
- is_master_push_repo: {{ $v.is_master_push_repo }}
- has_release_please: {{ $v.has_release_please | default "unset" }}
- role: {{ $v.role | default "unset" }}
