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

## Workflow: First Analyze, Then Act

**CRITICAL**: When editing an existing issue, ALWAYS start with `view` to understand the current state before deciding what to do.

### Step 1: Analyze with `view`

```bash
a gh issue-agent view <issue-number> [-R <owner/repo>]
```

Read the output carefully and identify:

1. What content exists in the issue body?
2. What comments already exist and what do they contain?
3. Based on user's request, determine the action:
    - Add content to issue body → Edit existing issue workflow
    - Add content to an existing comment → Edit existing comment workflow
    - Add a completely new comment → Add new comment workflow

**DO NOT skip this step.** Without understanding the current state, you cannot make the correct decision.

### Step 2: Choose the correct workflow

Based on Step 1 analysis:

#### Workflow A: Viewing only (no edits)

If user only wants to read the issue, the `view` command output is sufficient. No further action needed.

#### Workflow B: Creating a new issue

1. Check available templates: `a gh issue-agent init issue --list-templates [-R <owner/repo>]`
2. Generate boilerplate with appropriate template:
    - If templates exist, use: `a gh issue-agent init issue --template <template-name>`
    - If no templates or user prefers blank: `a gh issue-agent init issue --no-template`
    - **IMPORTANT**: Never assume `--no-template` without checking templates first
3. Edit the file at `~/.cache/gh-issue-agent/<owner>/<repo>/new/issue.md`
4. Run `a ai draft <file-path>` to open in WezTerm + Neovim for user review
5. Create the issue: `a gh issue-agent push ~/.cache/gh-issue-agent/<owner>/<repo>/new`
    - On success, the directory is renamed to `<issue-number>/`

#### Workflow C: Editing issue body/metadata

1. Pull the issue: `a gh issue-agent pull <issue-number>`
2. Edit `issue.md` or `metadata.json` in `~/.cache/gh-issue-agent/<owner>/<repo>/<issue-number>/`
3. Run `a ai draft <file-path>` to open the edited file in WezTerm + Neovim for user review
4. After user approval, apply changes: `a gh issue-agent push <issue-number>`

#### Workflow D: Editing an EXISTING comment

Use this when the content should be added to or modified in an existing comment.

1. Pull the issue: `a gh issue-agent pull <issue-number>`
2. List comments: `ls ~/.cache/gh-issue-agent/<owner>/<repo>/<issue-number>/comments/`
3. Read the target comment file (identified from Step 1 analysis)
4. Edit the comment file directly
5. Run `a ai draft <file-path>` for user review
6. Push changes: `a gh issue-agent push <issue-number>`

**Comment file format:**

- Named like `001_comment_<id>.md`, `002_comment_<id>.md`, etc.
- Metadata headers show author, creation date
- Only your own comments can be edited by default

#### Workflow E: Adding a NEW comment

Use this ONLY when a completely new, separate comment is needed. Do NOT use this when content should be added to an existing comment.

1. Pull the issue first (if not already): `a gh issue-agent pull <issue-number>`
2. Generate comment boilerplate: `a gh issue-agent init comment <issue-number>`
3. Edit the generated file in `~/.cache/gh-issue-agent/<owner>/<repo>/<issue-number>/comments/`
4. Run `a ai draft <file-path>` for user review
5. Push changes: `a gh issue-agent push <issue-number>`

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
