---
name: opensrc
description: 'Use opensrc to shallow-clone third-party package or repo source for code reading. TRIGGER when investigating the implementation of an npm/PyPI/crates.io package or a non-owned GitHub/GitLab/Bitbucket repo (e.g., "how does <pkg> implement X", "read the source of <pkg>", "find <symbol> in <pkg>"). SKIP for owned orgs (use ghq instead) and for first-party code in the current repo.'
---

# opensrc - Fetch third-party source for code reading

Use `opensrc` to materialize package/repo source on disk so it can be searched with `rg`, `ast-grep`, or read with file tools.

## When to use

- Investigating how a third-party package is implemented (npm/PyPI/crates.io)
- Reading source of a non-owned GitHub/GitLab/Bitbucket repo
- Cross-referencing a symbol or behavior across an external library

Do NOT use for:

- Owned orgs (clone via `ghq get -u <org>/<repo>` and work in `~/ghq/github.com/<org>/<repo>`)
- The current working repository

## Spec format

| Source        | Spec                              |
| ------------- | --------------------------------- |
| npm (default) | `zod`, `zod@3.22.0`               |
| PyPI          | `pypi:requests`                   |
| crates.io     | `crates:serde`                    |
| GitHub        | `owner/repo`, `github:owner/repo` |
| GitLab        | `gitlab:owner/repo`               |
| Bitbucket     | `bitbucket:owner/repo`            |

## Common commands

```bash
# Print path (fetches on cache miss). Use this in command substitution.
opensrc path zod
opensrc path zod@3.22.0
opensrc path pypi:requests

# Search inside a package
rg 'parse' "$(opensrc path zod)"
ast-grep --pattern 'function $F($_) { $$$ }' "$(opensrc path zod)"

# Pre-fetch without printing path
opensrc fetch react vue

# List cached entries
opensrc list
```

## Cache layout

Sources are cached under `~/.opensrc/repos/<host>/<owner>/<repo>/<version>/` (override with `OPENSRC_HOME`).

## Notes

- `opensrc path` prints to stdout only — wrap in `"$(...)"` to feed other tools
- Versions resolve from the spec (`@<ver>`) or the nearest lockfile when `--cwd` is given
- `remove` and `clean` are destructive and require confirmation
