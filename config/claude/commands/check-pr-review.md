# Check PR Review Comments

Fetch review comments for a PR and address any feedback.

## Usage

```bash
gh-check-pr-review <pr-number> [-R <owner/repo>] [--all] [--review N] [--full]
```

## Options

- `-R <owner/repo>`: Target repository (default: current repo)
- `-a, --all`: Include resolved comments (default: only unresolved)
- `-r, --review N`: Show details for review number N
- `-f, --full`: Show all details (original behavior)

## Output Modes

### Default (Summary)

Shows compact overview of all reviews with thread counts:
- Review author, state, unresolved thread count
- Thread locations (file:line) with first line of comment

### --review N

Shows full details for a specific review:
- Review body
- All associated threads with diff context and full comments

### --full

Shows all reviews and threads with full details (legacy behavior).

## Workflow

1. Run without options to get summary
2. Identify reviews that need attention
3. Use `--review N` to see details for each review
4. Make necessary code changes
5. Repeat for remaining reviews
