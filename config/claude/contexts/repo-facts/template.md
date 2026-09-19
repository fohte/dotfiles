{{- $v := ds "vars" -}}
{{- $repo := dict "name" "unset" "visibility" "unset" "owner" (dict "login" "unset") -}}
{{- if test.IsKind "map" $v.repo }}{{ $repo = $v.repo }}{{ end -}}
{{- /* repo.language defaults to "en" instead of "unset": `a config get repo.language` is empty (with exit 0) when the repo can't be identified, and English is a safe default there, unlike the other facts. */ -}}

## Repository facts

- repo.owner: {{ $repo.owner.login }}
- repo.name: {{ $repo.name }}
- repo.visibility: {{ $repo.visibility }}
- repo.language: {{ $v.repo_language | default "en" }}
- is_master_push_repo: {{ $v.is_master_push_repo }}
- has_release_please: {{ $v.has_release_please | default "unset" }}
- role: {{ $v.role | default "unset" }}
