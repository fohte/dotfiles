---
name: github-issue
description: Use gh-issue-agent to view and edit GitHub Issues. Use this skill when working with GitHub Issues - viewing issue content, editing issue body/title/labels, or adding/editing comments.
---

# GitHub Issue Management

Use `gh-issue-agent` to manage GitHub Issues as local files. This provides better diff visibility and safer editing compared to direct `gh issue` commands.

## When to Use

Use this skill when:
- Viewing GitHub Issue content (body, comments, metadata)
- Editing Issue body, title, or labels
- Adding or editing comments on Issues

## Commands

### Pull (fetch issue locally)

```bash
gh-issue-agent pull <issue-number> [-R <owner/repo>]
```

This saves the issue to `~/.cache/gh-issue-agent/<owner>/<repo>/<issue-number>/`:
- `issue.md` - Issue body (editable)
- `metadata.json` - Title, labels, assignees (editable)
- `comments/` - Comment files (only your own comments are editable)

### Push (apply changes to GitHub)

```bash
# Preview changes (compares with latest GitHub state)
gh-issue-agent push <issue-number> --dry-run

# Apply changes
gh-issue-agent push <issue-number>
```

## Workflow

1. Pull the issue: `gh-issue-agent pull 123`
2. Read/Edit files in `~/.cache/gh-issue-agent/<owner>/<repo>/123/`
3. Preview changes: `gh-issue-agent push 123 --dry-run`
4. Apply changes: `gh-issue-agent push 123`

## Editing Comments

- Only your own comments can be edited
- To add a new comment, create a file like `comments/new_<name>.md`
- Comment files have metadata in HTML comments at the top (author, id, etc.)

## Notes

- `push` always fetches latest from GitHub before comparing, so it handles concurrent edits safely
- Use `--dry-run` to preview what will be changed
- For other repos, use `-R owner/repo` option
