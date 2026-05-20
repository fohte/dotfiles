---
name: debug-renovate
description: Use renovate-dryrun to test Renovate configuration locally. Use this skill when debugging or validating renovate.json5 changes.
---

# Debug Renovate Configuration

Test Renovate configuration changes locally with the `renovate-dryrun` command. This wrapper script runs Renovate in dry-run mode against the current repository and displays a formatted summary of proposed updates.

## Usage

```bash
# Allocate a unique log path first so parallel sessions don't clobber each other
LOG=$(mktemp /tmp/renovate-dryrun.XXXXXX.log)

# Basic usage (token is optional; falls back to gh-token command)
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

- You MUST validate `renovate.json5` configuration file in the current directory. To validate:
    ```bash
    nlx -p renovate renovate-config-validator renovate.json5
    ```
- If the validator reports `disallowed fields` / `unknown field` for a field that is actually current (e.g. `managerFilePatterns`), suspect a stale npx cache rather than the config. Re-run with `--prefer-online` to force a staleness check and confirm the resolved version in the `npm warn exec ... renovate@<version>` line:
    ```bash
    nlx -p renovate --prefer-online renovate-config-validator renovate.json5
    ```
    The real Renovate runs on Mend Cloud at the latest version, so a stale local validator produces false positives that do not match CI. Do not edit `renovate.json5` to "fix" such errors before ruling out the cache.
- You SHOULD save output to a unique path under `/tmp/` (e.g. `mktemp /tmp/renovate-dryrun.XXXXXX.log`) since the command takes time and produces extensive output. Do not use a fixed filename — parallel sessions would overwrite each other.
- Token is optional. The script falls back to the `gh-token` command automatically. Do NOT require `--token` or `$GH_TOKEN` unless the user explicitly provides one.
- Push is NOT required before running dry-run. The command reads the local `renovate.json5` directly.
