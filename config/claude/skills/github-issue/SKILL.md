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

# Use a specific issue template
a gh issue-agent init issue --template <template-name>

# List available issue templates
a gh issue-agent init issue --list-templates

# Skip templates and use default boilerplate
a gh issue-agent init issue --no-template

# Create new comment boilerplate for an existing issue
a gh issue-agent init comment <issue-number> [--name <name>] [-R <owner/repo>]
```

**Issue template behavior:**

- If the repository has issue templates in `.github/ISSUE_TEMPLATE/`, they are automatically fetched
- If only one template exists, it is auto-selected
- If multiple templates exist, you must choose with `--template <name>` or `--no-template`
- Use `--list-templates` to see available templates

The `init issue` command creates a boilerplate file at `~/.cache/gh-issue-agent/<owner>/<repo>/new/issue.md`:

```markdown
---
title: Title
labels: []
assignees: []
---

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

1. Check available templates: `a gh issue-agent init issue --list-templates [-R <owner/repo>]`
2. Generate boilerplate with appropriate template:
    - If templates exist, use: `a gh issue-agent init issue --template <template-name>`
    - If no templates or user prefers blank: `a gh issue-agent init issue --no-template`
    - **IMPORTANT**: Never assume `--no-template` without checking templates first
3. Edit the file at `~/.cache/gh-issue-agent/<owner>/<repo>/new/issue.md`
4. Run `a ai draft <file-path>` to open in WezTerm + Neovim for user review
5. Create the issue: `a gh issue-agent push ~/.cache/gh-issue-agent/<owner>/<repo>/new`
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
- `push` uses field-level conflict detection: only fails if locally modified fields were also modified remotely
    - e.g., adding a label remotely does NOT block body edits
    - Use `--force` to overwrite remote changes when conflicts are detected
- `push` fails when editing other users' comments (use `--edit-others` to allow)
- `push` fails when deleting comments (use `--allow-delete` to allow)
- Before using `--force`, use `diff` or `push --dry-run` to verify what will be overwritten
- Always use `a ai draft <file-path>` to let user review edited content before pushing

## Writing Style

Follow these guidelines when writing issues or comments:

- Avoid unnecessary bold formatting
- Do not start list items with a summary followed by a colon. Write normal sentences instead
- When linking to external resources (e.g., other issues), explain why the link is relevant
- Use permalinks for GitHub source code links (include commit SHA instead of `main`/`master`)
    - Bad: `github.com/org/repo/blob/main/path/file.ts#L10`
    - Good: `github.com/org/repo/blob/abc123.../path/file.ts#L10`
    - Get latest commit SHA: `gh api -X GET repos/org/repo/commits -F path=<file> -F per_page=1 --jq '.[0].sha'`
- Use である調 (plain form), not ですます調 (polite form)
- Do not make recommendations or suggestions - only present facts and findings
- Place reference links inline where contextually relevant, not in a separate "References" section at the end
- Use numbered lists only when order matters (sequential steps, priority ranking); otherwise use bullet points
    - Bad: `1. Option A 2. Option B 3. Option C` (options have no inherent order)
    - Good: `- Option A - Option B - Option C`
- Issue titles must be specific about the problem - avoid vague words like "improvement" or "fix" without context
- When multiple problems share a root cause, consolidate them under that root cause rather than listing separately
- The What section should include proposed solutions, not just problem descriptions

## Notes

- For other repos, use `-R owner/repo` option
