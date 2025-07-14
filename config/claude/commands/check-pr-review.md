# Check PR Review Comments

## Fetch review comments

Get all review comments for the PR:
```bash
gh api repos/{owner}/{repo}/pulls/{pr_number}/comments --paginate
```

This returns comments with location information including:
- `path`: The file path
- `line` or `original_line`: The line number
- `diff_hunk`: The diff context
- `body`: The comment text
