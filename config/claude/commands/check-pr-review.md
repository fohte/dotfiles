# Check PR Review Comments

Fetch review comments for a PR and address any feedback.

## Usage

```bash
gh-check-pr-review <pr-number> [-R <owner/repo>] [--all]
```

## Options

- `-R <owner/repo>`: Target repository (default: current repo)
- `-a, --all`: Include resolved comments (default: only unresolved)

## Output

Comments are grouped by thread with:
- Author and timestamp
- Diff context with line numbers (via delta)
- Comment body (rendered with glow)
- Replies with tree structure

## Workflow

1. Fetch review comments
2. Analyze each comment
3. Make necessary code changes
