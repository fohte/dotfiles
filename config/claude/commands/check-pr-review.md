# Check PR Review Comments

Fetch review comments for a PR and address any feedback.

## Usage

```bash
gh-check-pr-review <pr-number> [-R <owner/repo>]
```

## Output

Comments are grouped by file path with:
- Line number (or range)
- Author
- Diff context (3 lines)
- Comment body

## Workflow

1. Fetch review comments
2. Analyze each comment
3. Make necessary code changes
