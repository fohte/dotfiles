# Create PR

First, push your changes, then follow these steps:

## 1. Create a PR with the `gh pr create` command

Use this format for the PR description:
```markdown
## Why

- Why is this PR necessary? (purpose/background/motivation)

## What

- What will change when this PR is merged? (describe the overall impact in present tense, not individual commits)
```

## 2. Watch the CI execution

Use `gh pr checks --watch` command to monitor the CI checks.
If CI passes, you're done. If it fails, investigate the cause, fix it, and push again.
