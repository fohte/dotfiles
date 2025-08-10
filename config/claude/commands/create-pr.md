# Create PR

After pushing your changes, follow these steps:

## 1. Create a PR with the `gh pr create` command

Use this format for the PR description:

```markdown
## Why

- Why is this PR necessary? (Explain the purpose, background, or motivation)

## What

- What will change when this PR is merged? (Describe the overall impact in present tense, not individual commits)
```

### Notes

- Format text with markdown (`code`, **bold**, *italic*) for better readability
- Group related items using nested bullet points
- Do not include any references for fohte/tasks issues, as this is a private repository

## 2. Watch the CI execution

Use `gh pr checks --watch` command to monitor the CI checks.
If CI passes, you're done. If it fails, investigate and fix the issue, then push again.
