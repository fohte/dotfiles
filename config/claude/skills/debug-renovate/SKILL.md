---
name: debug-renovate
description: Use renovate-dryrun to test Renovate configuration locally. Use this skill when debugging or validating renovate.json5 changes.
---

# Debug Renovate Configuration

Test Renovate configuration changes locally with the `renovate-dryrun` command. This wrapper script runs Renovate in dry-run mode against the current repository and displays a formatted summary of proposed updates.

## Usage

```bash
# Basic usage (token is optional; falls back to gh-token command)
renovate-dryrun > .z/renovate-dryrun.log

# Test specific branch (defaults to current branch)
renovate-dryrun --branch feature/update-deps > .z/renovate-dryrun.log

# Debug mode with raw Renovate output
renovate-dryrun --raw > .z/renovate-debug.log
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
    # Validate renovate.json5 in current directory
    npx --package renovate -c 'renovate-config-validator renovate.json5'
    ```
- You SHOULD save output to `.z/` since the command takes time and produces extensive output.
- Token is optional. The script falls back to the `gh-token` command automatically. Do NOT require `--token` or `$GH_TOKEN` unless the user explicitly provides one.
- Push is NOT required before running dry-run. The command reads the local `renovate.json5` directly.
