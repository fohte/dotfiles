---
name: github-issue
description: Use `a gh issue-agent` to view and edit GitHub Issues. Use this skill when working with GitHub Issues - viewing issue content, editing issue body/title/labels, or adding/editing comments.
---

# GitHub Issue Management

Use `a gh issue-agent` to manage GitHub Issues as local files. This provides better diff visibility and safer editing compared to direct `gh issue` commands.

## When to Use

Use this skill when:

- Viewing GitHub Issue content (body, comments, metadata)
- Editing Issue body, title, or labels
- Adding or editing comments on Issues

## Commands

### View (read-only)

```bash
a gh issue-agent view <issue-number> [-R <owner/repo>]
```

Use this when you only need to **read** the issue content. No local cache is created.

**When to use `view` vs `pull`:**

- `view`: Just reading/viewing the issue (no editing needed)
- `pull`: When you plan to edit the issue body, metadata, or comments

### Pull (fetch issue locally)

```bash
a gh issue-agent pull <issue-number> [-R <owner/repo>]
```

This saves the issue to `~/.cache/gh-issue-agent/<owner>/<repo>/<issue-number>/`:

- `issue.md` - Issue body (editable)
- `metadata.json` - Title, labels, assignees (editable)
- `comments/` - Comment files (only your own comments are editable)

**Note**: Fails if local changes exist. Use `refresh` to discard and re-fetch.

### Refresh (discard local changes and re-fetch)

```bash
a gh issue-agent refresh <issue-number> [-R <owner/repo>]
```

Use this when you want to discard local changes and get the latest from GitHub.

### Push (apply changes to GitHub)

```bash
# Apply changes
a gh issue-agent push <issue-number>

# Force overwrite if remote has changed since pull
a gh issue-agent push <issue-number> --force

# Edit other users' comments
a gh issue-agent push <issue-number> --edit-others

# Allow deleting comments from GitHub
a gh issue-agent push <issue-number> --allow-delete
```

## Workflow

### Viewing only (no edits)

```bash
a gh issue-agent view 123
```

### Editing

1. Pull the issue: `a gh issue-agent pull 123`
2. Read/Edit files in `~/.cache/gh-issue-agent/<owner>/<repo>/123/`
3. Run `a ai draft <file-path>` to open the edited file in WezTerm + Neovim for user review
4. After user approval (user closes the editor), apply changes: `a gh issue-agent push 123`

## Editing Comments

- Only your own comments can be edited by default
- To edit other users' comments, use `--edit-others` flag
- To add a new comment, create a file like `comments/new_<name>.md`
- Comment files have metadata in HTML comments at the top (author, id, etc.)

## Safety Features

- `pull` fails if local changes exist (use `refresh` to discard)
- `push` fails if remote has changed since pull (use `--force` to overwrite)
- `push` fails when editing other users' comments (use `--edit-others` to allow)
- `push` fails when deleting comments (use `--allow-delete` to allow)
- Always use `a ai draft <file-path>` to let user review edited content before pushing

## Writing Style

Follow these guidelines when writing issues or comments:

- Avoid unnecessary bold formatting
- Do not start list items with a summary followed by a colon. Write normal sentences instead
- When linking to external resources (e.g., other issues), explain why the link is relevant

## Notes

- For other repos, use `-R owner/repo` option
