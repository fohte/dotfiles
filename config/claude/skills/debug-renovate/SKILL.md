---
name: debug-renovate
description: Use renovate-dryrun to test Renovate configuration locally. Use this skill when debugging or validating renovate.json5 changes.
---

# Debug Renovate Configuration

Test Renovate configuration changes locally with the `renovate-dryrun` command. This wrapper script runs Renovate in dry-run mode against the current repository and displays a formatted summary of proposed updates.

## Usage

```bash
# Allocate a unique log path first so runs in this session do not clobber each other
LOG=$(mktemp "$AGENT_TMPDIR/renovate-dryrun.XXXXXX.log")

# Basic usage (token is optional; falls back to gh auth token)
renovate-dryrun > "$LOG"

# Test specific branch (defaults to current branch)
renovate-dryrun --branch feature/update-deps > "$LOG"

# Debug mode with raw Renovate output
renovate-dryrun --raw > "$LOG"
```

The output displays proposed updates in this format:

```
[renovate/aws-5.x] chore(deps): update terraform aws to v5.68.0 (automerge: true)
  depName: aws
  version: 5.49.0 -> 5.68.0
  datasource: terraform-provider
  packageFile: terraform/tfaction/main.tf
```

## Important Notes

- Validate `renovate.json5` with:

    ```bash
    container run --rm -v "$PWD:/repo" -w /repo \
      ghcr.io/renovatebot/renovate:latest \
      renovate-config-validator --strict --no-global renovate.json5
    ```

    - Without `--no-global`, repo-config-only fields (e.g. `customManagers[].managerFilePatterns`) pass silently because the file is treated as global config
    - Pin the image to `:latest`. Do not use `:slim` or `npx renovate`

- You SHOULD save output to a file created with `mktemp "$AGENT_TMPDIR/renovate-dryrun.XXXXXX.log"` since the command takes time and produces extensive output.
- Token is optional. The script falls back to `gh auth token` automatically. Do NOT require `--token` or `$GH_TOKEN` unless the user explicitly provides one.
- Push is NOT required before running dry-run. The command reads the local `renovate.json5` directly.
