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

| Source        | Spec                                                  |
| ------------- | ----------------------------------------------------- |
| npm (default) | `zod`, `zod@3.22.0`                                   |
| PyPI          | `pypi:requests`, `pypi:requests@2.31.0`               |
| crates.io     | `crates:serde`, `crates:serde@1.0.0`                  |
| GitHub        | `owner/repo`, `owner/repo@<ref>`, `github:owner/repo` |
| GitLab        | `gitlab:owner/repo`, `gitlab:owner/repo@<ref>`        |
| Bitbucket     | `bitbucket:owner/repo`, `bitbucket:owner/repo@<ref>`  |

`<ref>` accepts a tag, branch, or commit SHA. Defaults to the repo's default branch.

## Always pin the ref/version in the spec

To read a different ref or version, do NOT `git checkout`, `git switch`, or otherwise mutate the cache directory. The cache is keyed per ref (`.../<repo>/<ref>/`); checking out inside it corrupts the cached state for that ref.

Instead, append `@<ref>` to the spec and call `opensrc path` again. A cache miss triggers a fresh fetch automatically.

```bash
# OK: pin the ref in the spec
rg 'parse' "$(opensrc path 'colinhacks/zod@v4.0.0')"
rg 'parse' "$(opensrc path 'colinhacks/zod@main')"
rg 'parse' "$(opensrc path 'colinhacks/zod@abc1234')"

# NG: do not checkout/switch inside the cache
cd "$(opensrc path zod)" && git checkout v4.0.0   # don't
```

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
