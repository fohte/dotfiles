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

Use `gh pr checks --watch` command to monitor the CI checks.
If CI passes, you're done. If it fails, investigate the cause, fix it, and push again.
