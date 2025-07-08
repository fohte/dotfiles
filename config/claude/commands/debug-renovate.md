# Debug Renovate Configuration

Test Renovate configuration changes locally with the `renovate-dryrun` command. This wrapper script runs Renovate in dry-run mode against the current repository and displays a formatted summary of proposed updates.

## Usage

```bash
# Basic usage
renovate-dryrun --token $GH_TOKEN > .claude/tmp/renovate-dryrun.log

# Test specific branch (defaults to current branch)
renovate-dryrun --token $GH_TOKEN --branch feature/update-deps > .claude/tmp/renovate-dryrun.log

# Debug mode with raw Renovate output
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

- You MUST validate `renovate.json5` configuration file in the current directory. To validate:
    ```bash
    # Validate renovate.json5 in current directory
    npx --package renovate -c 'renovate-config-validator renovate.json5'
    ```
- You SHOULD save output to `.claude/tmp/` since the command takes time and produces extensive output:
- You MUST specify `--token $GH_TOKEN`. Use the `$GH_TOKEN` environment variable, not `$GITHUB_TOKEN`.
