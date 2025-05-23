# Custom Instructions for AI Model

## Pull Request Format

When creating pull requests, use the following format:

```markdown
## Why

<!-- Explain why this change is being made, including the purpose and background. Use bullet points. -->

## What

<!-- Describe what changes are being made. Use present tense, not past tense. Use bullet points. -->
```

## CI Status Check

After creating a pull request and pushing changes, check the CI status using:

```bash
gh run watch $(gh run list --limit 1 --json databaseId --jq '.[0].databaseId')
```

## Code Comments

- **MUST** write code comments in English
- **SHOULD** focus on explaining "why" or "why not" in comments, rather than "what" or "how"
