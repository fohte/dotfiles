---
name: github-issue
description: Use `a gh issue-agent` to view, create, and edit GitHub Issues. Use this skill when working with GitHub Issues - viewing issue content, creating new issues, editing issue body/title/labels, or adding/editing comments.
---

# GitHub Issue Management

Use `a gh issue-agent` to manage GitHub Issues as local files. This provides better diff visibility and safer editing compared to direct `gh issue` commands.

## When to Use

Use this skill when:

- Viewing GitHub Issue content (body, comments, metadata, timeline events)
- Creating new GitHub Issues
- Editing Issue body, title, or labels
- Adding or editing comments on Issues

## Commands

### View (read-only)

```bash
a gh issue-agent view <issue-number> [-R <owner/repo>]
```

Use this when you only need to **read** the issue content. No local cache is created.

The view command displays:

- Issue body and metadata
- Comments
- Timeline events (label changes, assignments, cross-references from other issues/PRs)

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

**Note**: Fails if local changes exist. Use `pull --force` to discard and re-fetch.

### Init (create boilerplate)

```bash
# Create new issue boilerplate
a gh issue-agent init issue [-R <owner/repo>]

# Create new comment boilerplate for an existing issue
a gh issue-agent init comment <issue-number> [--name <name>] [-R <owner/repo>]
```

The `init issue` command creates a boilerplate file at `~/.cache/gh-issue-agent/<owner>/<repo>/new/issue.md`:

```markdown
---
labels: []
assignees: []
---

# Title

Body
```

### Diff (show changes)

```bash
a gh issue-agent diff <issue-number> [-R <owner/repo>]
```

Shows colored diff between local changes and remote state. Useful for reviewing changes before pushing.

### Push (apply changes to GitHub)

```bash
# Update existing issue
a gh issue-agent push <issue-number>

# Create new issue (pass path instead of number)
a gh issue-agent push <path-to-new-issue-dir>

# Preview changes without applying
a gh issue-agent push <issue-number> --dry-run

# Force overwrite if remote has changed since pull
a gh issue-agent push <issue-number> --force

# Edit other users' comments
a gh issue-agent push <issue-number> --edit-others

# Allow deleting comments from GitHub
a gh issue-agent push <issue-number> --allow-delete
```

## Workflows

### Viewing only (no edits)

```bash
a gh issue-agent view 123
```

### Creating a new issue

1. Generate boilerplate: `a gh issue-agent init issue`
2. Edit the file at `~/.cache/gh-issue-agent/<owner>/<repo>/new/issue.md`
3. Run `a ai draft <file-path>` to open in WezTerm + Neovim for user review
4. Create the issue: `a gh issue-agent push ~/.cache/gh-issue-agent/<owner>/<repo>/new`
    - On success, the directory is renamed to `<issue-number>/`

### Editing an existing issue

1. Pull the issue: `a gh issue-agent pull 123`
2. Read/Edit files in `~/.cache/gh-issue-agent/<owner>/<repo>/123/`
3. Run `a ai draft <file-path>` to open the edited file in WezTerm + Neovim for user review
4. After user approval, apply changes: `a gh issue-agent push 123`

### Adding a comment

1. Generate comment boilerplate: `a gh issue-agent init comment 123`
2. Edit the generated file in `~/.cache/gh-issue-agent/<owner>/<repo>/123/comments/`
3. Run `a ai draft <file-path>` for user review
4. Push changes: `a gh issue-agent push 123`

## Editing Comments

- Only your own comments can be edited by default
- To edit other users' comments, use `--edit-others` flag
- Comment files have metadata in HTML comments at the top (author, id, etc.)

## Safety Features

- `pull` fails if local changes exist (use `--force` to discard)
- `push` fails if remote has changed since pull (use `--force` to overwrite)
- `push` fails when editing other users' comments (use `--edit-others` to allow)
- `push` fails when deleting comments (use `--allow-delete` to allow)
- Before using `--force`, use `diff` or `push --dry-run` to verify what will be overwritten
- Always use `a ai draft <file-path>` to let user review edited content before pushing

## Writing Style

Follow these guidelines when writing issues or comments:

- Avoid unnecessary bold formatting
- Do not start list items with a summary followed by a colon. Write normal sentences instead
- When linking to external resources (e.g., other issues), explain why the link is relevant
- Use である調 (plain form), not ですます調 (polite form)
- Do not make recommendations or suggestions - only present facts and findings
- Place reference links inline where contextually relevant, not in a separate "References" section at the end

## Notes

- For other repos, use `-R owner/repo` option
