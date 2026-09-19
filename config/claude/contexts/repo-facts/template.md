{{- $v := ds "vars" -}}
{{- $repo := dict "name" "unset" "visibility" "unset" "owner" (dict "login" "unset") -}}
{{- if test.IsKind "map" $v.repo }}{{ $repo = $v.repo }}{{ end -}}

## Repository facts

- repo.owner: {{ $repo.owner.login }}
- repo.name: {{ $repo.name }}
- repo.visibility: {{ $repo.visibility }}
- repo.language: {{ $v.repo_language | default "unset" }}
- is_master_push_repo: {{ $v.is_master_push_repo }}
- has_release_please: {{ $v.has_release_please | default "unset" }}
- role: {{ $v.role | default "unset" }}
