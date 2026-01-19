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

### View (read-only)

```bash
gh-issue-agent view <issue-number> [-R <owner/repo>]
```

Use this when you only need to **read** the issue content. No local cache is created.

**When to use `view` vs `pull`:**

- `view`: Just reading/viewing the issue (no editing needed)
- `pull`: When you plan to edit the issue body, metadata, or comments

### Pull (fetch issue locally)

```bash
gh-issue-agent pull <issue-number> [-R <owner/repo>]
```

This saves the issue to `~/.cache/gh-issue-agent/<owner>/<repo>/<issue-number>/`:

- `issue.md` - Issue body (editable)
- `metadata.json` - Title, labels, assignees (editable)
- `comments/` - Comment files (only your own comments are editable)

**Note**: Fails if local changes exist. Use `refresh` to discard and re-fetch.

### Refresh (discard local changes and re-fetch)

```bash
gh-issue-agent refresh <issue-number> [-R <owner/repo>]
```

Use this when you want to discard local changes and get the latest from GitHub.

### Push (apply changes to GitHub)

```bash
# Apply changes
gh-issue-agent push <issue-number>

# Force overwrite if remote has changed since pull
gh-issue-agent push <issue-number> --force

# Edit other users' comments
gh-issue-agent push <issue-number> --edit-others
```

## Workflow

### Viewing only (no edits)

```bash
gh-issue-agent view 123
```

### Editing

1. Pull the issue: `gh-issue-agent pull 123`
2. Read/Edit files in `~/.cache/gh-issue-agent/<owner>/<repo>/123/`
3. Show the draft file path to user for review
4. After user approval, apply changes: `gh-issue-agent push 123`

**Note**: Show the draft content to the user for review before pushing.

## Editing Comments

- Only your own comments can be edited by default
- To edit other users' comments, use `--edit-others` flag
- To add a new comment, create a file like `comments/new_<name>.md`
- Comment files have metadata in HTML comments at the top (author, id, etc.)

## Safety Features

- `pull` fails if local changes exist (use `refresh` to discard)
- `push` fails if remote has changed since pull (use `--force` to overwrite)
- `push` fails when editing other users' comments (use `--edit-others` to allow)
- Always show edited content to user for review before pushing

## Notes

- For other repos, use `-R owner/repo` option
