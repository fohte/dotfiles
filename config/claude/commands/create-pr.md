# Create PR

First, push your changes, then follow these steps:

## 1. Create a PR with the `gh pr create` command

Use this format for the PR description:
```markdown
## Why

- purpose/background

## What

- changes in present tense
```

## 2. Watch the CI execution

```bash
gh run watch $(gh run list --limit 1 --json databaseId --jq '.[0].databaseId')
```

If CI passes, you're done. If it fails, investigate the cause, fix it, and push again.
