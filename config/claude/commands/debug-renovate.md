# Debug Renovate Configuration

Test Renovate configuration changes locally with the `renovate-dryrun` command. This wrapper script runs Renovate in dry-run mode against the current repository and displays a formatted summary of proposed updates.

## Usage

```bash
# Basic usage
renovate-dryrun --token $GH_TOKEN

# Test specific branch (defaults to current branch)
renovate-dryrun --token $GH_TOKEN --branch feature/update-deps

# Debug mode with raw output (save to .claude/tmp/ due to large output)
renovate-dryrun --token $GH_TOKEN --raw > .claude/tmp/renovate-debug.log
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

- Requires a valid `renovate.json5` configuration file in the current directory. To validate:
    ```bash
    # Validate renovate.json5 in current directory
    npx --package renovate -c 'renovate-config-validator renovate.json5'
    ```
- Always specify `--token $GH_TOKEN`. Use the `$GH_TOKEN` environment variable, not `$GITHUB_TOKEN`.
- The `--raw` option outputs unformatted Renovate logs. Due to the verbose output, redirect to `.claude/tmp/` for easier review.
