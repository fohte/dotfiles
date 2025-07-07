# Debug Renovate Configuration

Test Renovate configuration changes locally using the `renovate-dryrun` command. This wrapper script runs Renovate in dry-run mode on the current repository and provides formatted output of what updates would be created.

## 1. Validate configuration

Before running Renovate, validate your configuration file syntax:

```bash
# Validate renovate.json5 in current directory
npx --package renovate -c 'renovate-config-validator renovate.json5'
```

This checks for:
- JSON/JSON5 syntax errors
- Invalid configuration options
- Type mismatches in configuration values
- Deprecated options
- Config migrations needed

Example output:
```
INFO: Validating renovate.json5
INFO: Config validated successfully
```

If migrations are needed:
```
INFO: Validating renovate.json5
WARN: Config migration necessary
      "oldConfig": { ... }
      "newConfig": { ... }
INFO: Config validated successfully
```

## 2. Basic usage

Run from inside a git repository:

```bash
renovate-dryrun --token $GH_TOKEN
```

**Important**: Use `$GH_TOKEN` environment variable, not `$GITHUB_TOKEN`.

## 3. Output format

Shows proposed updates in this format:
```
[renovate/aws-5.x] chore(deps): update terraform aws to v5.68.0 (automerge: true)
  depName: aws
  version: 5.49.0 -> 5.68.0
  datasource: terraform-provider
  packageFile: terraform/tfaction/main.tf
```

## 4. Common usage patterns

### Test configuration changes
```bash
# Edit renovate.json5, then test
renovate-dryrun --token $GH_TOKEN
```

### Debug with different config file
```bash
renovate-dryrun --token $GH_TOKEN -c renovate.dev.json5
```

### Get raw debug logs
When debugging complex issues, use `--raw` option. Since output is extensive, save to `.claude/tmp/`:
```bash
renovate-dryrun --token $GH_TOKEN --raw > .claude/tmp/renovate-debug.log
```

### Test specific branch
```bash
renovate-dryrun --token $GH_TOKEN --branch feature/update-deps
```
