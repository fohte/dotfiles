---
name: github-issue
description: Use `a gh issue-agent` to view, create, and edit GitHub Issues. Use this skill when working with GitHub Issues - viewing issue content, creating new issues, editing issue body/title/labels, or adding/editing comments. IMPORTANT - This skill MUST be used instead of running `gh issue create`, `gh issue edit`, or `gh issue comment` directly. Any GitHub Issue operation (create, view, edit, comment) must go through this skill.
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
- `metadata.json` - Title, labels, assignees, sub-issues, parent issue (editable)
- `comments/` - Comment files (only your own comments are editable)

Sub-issues are automatically fetched via the GitHub Sub-issues REST API during `pull`.

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

Sub-issues and parent issue can also be specified in the frontmatter (see "Sub-issues and Parent Issue" section below).

### Review (approve before push)

```bash
a gh issue-agent review <file-path>
```

Opens a file in an editor (via tmux) for user review. The user must set `submit: true` in the frontmatter to approve. For files without YAML frontmatter (e.g., comment files with HTML comment metadata), a temporary `submit: false` frontmatter is prepended and stripped after review.

Run this **in background** (`run_in_background: true`). The command blocks until the user closes the editor. Exit code 0 means approved, exit code 1 means cancelled.

The `push` command verifies `.approve` files exist for all changed files and rejects the push if any file is unapproved.

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

## Sub-issues and Parent Issue

`a gh issue-agent` supports managing GitHub Sub-issues via the [Sub-issues API](https://docs.github.com/en/rest/issues/sub-issues). Sub-issues and parent issue relationships are managed through `metadata.json` frontmatter fields.

### Frontmatter fields

When you `pull` an issue, `metadata.json` includes:

- `sub_issues`: array of issue references that are sub-issues of this issue
- `parent_issue`: the parent issue reference if this issue is a sub-issue

Reference format: `owner/repo#number` (e.g., `org/my-repo#42`)

Example `metadata.json` with sub-issues:

```json
{
  "title": "Parent task",
  "labels": [],
  "sub_issues": ["org/repo#10", "org/repo#20"],
  "parent_issue": "org/repo#5",
  "readonly": { ... }
}
```

### How it works

- **pull**: Sub-issues are automatically fetched via REST API (`GET /repos/{owner}/{repo}/issues/{number}/sub_issues`). Parent issue is fetched via GraphQL (`parent` field).
- **push**: Diffs are computed between local and remote state. Changes are applied via the Sub-issues API:
    - Adding a sub-issue: `POST /repos/{owner}/{repo}/issues/{parent_number}/sub_issues` with `{ "sub_issue_id": <id> }`
    - Removing a sub-issue: `DELETE /repos/{owner}/{repo}/issues/{parent_number}/sub_issue` with `{ "sub_issue_id": <id> }`
    - Changing parent issue: removes from old parent, adds to new parent (by manipulating the parent's sub-issue list)
- The API uses internal issue IDs (not issue numbers). `a gh issue-agent` resolves issue numbers to IDs automatically via `GET /repos/{owner}/{repo}/issues/{number}`.

### Usage examples

**Add a sub-issue to an existing issue:**

1. `a gh issue-agent pull 100`
2. Edit `metadata.json`: add `"org/repo#42"` to the `sub_issues` array
3. Review and push as usual

**Set a parent issue:**

1. `a gh issue-agent pull 42`
2. Edit `metadata.json`: set `"parent_issue": "org/repo#100"`
3. Review and push as usual

**Create an issue with sub-issues:**

In the `issue.md` frontmatter for a new issue, include:

```markdown
---
title: Parent task
labels: []
assignees: []
sub_issues:
    - org/repo#10
    - org/repo#20
---
```

## Absolute Rules

These rules MUST NEVER be violated, regardless of context or convenience.

1. NEVER call `a gh issue-agent push` without first running `a gh issue-agent review` on every changed file and having the user approve each one (by setting `submit: true` in the frontmatter). The `push` command verifies `.approve` files exist for all changed files and will reject the push if any file is unapproved. No exceptions - not even when "continuing from a previous session", "the content was already reviewed", or "the changes are minor". If `a gh issue-agent review` was not run in the current conversation turn, the content has NOT been reviewed.
2. NEVER put flow information (investigation results, root cause analysis, data tables, timeline of events, action items, options/choices) in the issue body. The issue body is for static, structural content only: WHY (motivation, severity, risk) and WHAT (strategic intent, completion criteria). All flow information goes in comments.
3. NEVER push issue body changes and new comments in the same `push` command. Each must be reviewed (`a gh issue-agent review` with `submit: true`) and pushed separately. Edit the issue body first, get approval, push it, then create the comment, get approval, push it.
4. NEVER paraphrase, summarize, or edit external text provided by the user (e.g., support correspondence, Slack messages, email threads). Copy-paste the original text exactly as-is. The only acceptable changes are formatting adjustments for Markdown rendering (e.g., adding `>` for quotes). If the user provides text to include in a comment, use it verbatim.
5. NEVER duplicate content that already exists in the issue's other comments. Before writing a new comment, read all existing comments and exclude any information already present. For example, if a support inquiry was already posted in an earlier comment, only include subsequent replies in the new comment.
6. NEVER change the structure or formatting that the user has established. If the user edits a file via `a gh issue-agent review` and establishes a particular structure (e.g., separate `<details>` blocks for different parties, specific heading styles), preserve that exact structure in subsequent edits. Do not reorganize, merge, or rename sections.

### Issue Body vs Comment Decision Guide

Before writing anything, classify each piece of information:

| Content type      | Where it belongs | Examples                                                                                                      |
| ----------------- | ---------------- | ------------------------------------------------------------------------------------------------------------- |
| Static/structural | Issue body       | Why this issue exists, what the goal is, completion criteria, severity/urgency                                |
| Flow/temporal     | Comment          | Investigation results, root cause findings, data analysis, proposed options, progress updates, decisions made |

The test: "Will this content change as work progresses?" If yes → comment. If no → issue body.

- Bad: Issue body contains `## 原因` or `## 調査結果` or `## 対応方針の選択肢`
- Good: Issue body contains only WHY + WHAT. Investigation results posted as a separate comment

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

**Phase 1: Gather information before writing**

Before writing anything, complete all necessary research. The goal is to write a high-quality draft on the first attempt, minimizing review rounds.

1. Extract from the user's description:
    - The priority/emphasis the user places on each topic (reflect this in section ordering)
    - Issue numbers or URLs the user explicitly mentions as related
    - Facts the user states without linking to specific issues (do not invent links for these)
2. Research external services/tools mentioned in the issue:
    - If the issue references features of an external service (e.g., a SaaS plan's capabilities), fetch the official documentation BEFORE writing the draft
    - Include specific feature names, API endpoints, or capability descriptions from the docs
3. Verify related issues:
    - For issues the user explicitly mentioned: confirm they exist with `gh issue view`
    - Do NOT proactively search for and add issue links the user did not mention. If you believe an issue is relevant, ask the user first rather than including it in the draft
    - If you do add an issue link, you MUST read the issue body (via `view`) to confirm it is actually relevant. Never link based on title alone
4. Check repository conventions: use `view` on a similar existing issue to match formatting

**Phase 2: Create and review**

1. Check available templates: `a gh issue-agent init issue --list-templates [-R <owner/repo>]`
2. Generate boilerplate with appropriate template:
    - If templates exist, use: `a gh issue-agent init issue --template <template-name>`
    - If no templates or user prefers blank: `a gh issue-agent init issue --no-template`
    - **IMPORTANT**: Never assume `--no-template` without checking templates first
3. Edit the file at `~/.cache/gh-issue-agent/<owner>/<repo>/new/issue.md`
4. Run `a gh issue-agent review <file-path>` **in background** (`run_in_background: true`) to open in terminal + Neovim for user review. This command blocks until the user closes the editor, so it will complete when the user finishes reviewing.
5. **STOP and wait for the background command to complete.** Do NOT proceed to push until the command finishes. When it completes, check the exit code: exit code 0 means the user approved the draft (set `submit: true` in frontmatter), exit code 1 means the user cancelled. If cancelled, ask the user what to change.
6. Create the issue: `a gh issue-agent push ~/.cache/gh-issue-agent/<owner>/<repo>/new` (the push command verifies `.approve` files exist for all changed files)
    - On success, the directory is renamed to `<issue-number>/`

#### Workflow C: Editing issue body/metadata

1. Pull the issue: `a gh issue-agent pull <issue-number>`
2. Edit `issue.md` or `metadata.json` in `~/.cache/gh-issue-agent/<owner>/<repo>/<issue-number>/`
3. Run `a gh issue-agent review <file-path>` **in background** (`run_in_background: true`) to open the edited file in terminal + Neovim for user review. This command blocks until the user closes the editor.
4. **STOP and wait for the background command to complete.** Do NOT proceed to push until the command finishes. When it completes, check the exit code: exit code 0 means the user approved, exit code 1 means cancelled. If cancelled, ask the user what to change.
5. Apply changes: `a gh issue-agent push <issue-number>` (the push command verifies `.approve` files exist for all changed files)

#### Workflow D: Editing an EXISTING comment

Use this when the content should be added to or modified in an existing comment.

1. Pull the issue: `a gh issue-agent pull <issue-number>`
2. List comments: `ls ~/.cache/gh-issue-agent/<owner>/<repo>/<issue-number>/comments/`
3. Read the target comment file (identified from Step 1 analysis)
4. Edit the comment file directly
5. Run `a gh issue-agent review <file-path>` **in background** (`run_in_background: true`) for user review. This command blocks until the user closes the editor.
6. **STOP and wait for the background command to complete.** Do NOT proceed to push until the command finishes. When it completes, check the exit code: exit code 0 means approved, exit code 1 means cancelled. If cancelled, ask the user what to change.
7. Push changes: `a gh issue-agent push <issue-number>` (the push command verifies `.approve` files exist)

**Comment file format:**

- Named like `001_comment_<id>.md`, `002_comment_<id>.md`, etc.
- Metadata headers show author, creation date
- Only your own comments can be edited by default

#### Workflow E: Adding a NEW comment

Use this ONLY when a completely new, separate comment is needed. Do NOT use this when content should be added to an existing comment.

1. Pull the issue first (if not already): `a gh issue-agent pull <issue-number>`
2. Generate comment boilerplate: `a gh issue-agent init comment <issue-number>`
3. Edit the generated file in `~/.cache/gh-issue-agent/<owner>/<repo>/<issue-number>/comments/`
4. Run `a gh issue-agent review <file-path>` **in background** (`run_in_background: true`) for user review. This command blocks until the user closes the editor.
5. **STOP and wait for the background command to complete.** Do NOT proceed to push until the command finishes. When it completes, check the exit code: exit code 0 means approved, exit code 1 means cancelled. If cancelled, ask the user what to change.
6. Push changes: `a gh issue-agent push <issue-number>` (the push command verifies `.approve` files exist)

## Editing Comments

- Only your own comments can be edited by default
- To edit other users' comments, use `--edit-others` flag
- Comment files have metadata in HTML comments at the top (author, id, etc.)

## Safety Features

- `pull` fails if local changes exist (use `--force` to discard)
- `push` uses field-level conflict detection: only fails if locally modified fields were also modified remotely
    - e.g., adding a label remotely does NOT block body edits
    - When a conflict occurs, `pull --force` to re-fetch the latest state, re-apply edits, and push again. NEVER use `push --force`
- **NEVER use `push --force`**. `push --force` blindly overwrites remote changes without merging. If `push` fails due to a conflict, always resolve by `pull --force` → re-edit → push
- `push` fails when editing other users' comments (use `--edit-others` to allow)
- `push` fails when deleting comments (use `--allow-delete` to allow)
- Before using `--force` on `pull`, use `diff` or `push --dry-run` to verify what local changes will be lost
- Always use `a gh issue-agent review <file-path>` **in background** (`run_in_background: true`) to let user review edited content before pushing. The user approves by setting `submit: true` in the frontmatter within Neovim. The `push` command verifies `.approve` files exist for all changed files and rejects the push if any file is unapproved.
- **CRITICAL: After running `a gh issue-agent review` in background, STOP and wait for the background command to complete.** Do NOT proceed to `push` until the command finishes. Exit code 0 means approved, exit code 1 means cancelled.

## Writing Style

**まず ~/.claude/skills/github-issue/writing-guide.md を読み込むこと。** Issue 本文とコメントの書き方ルールが定義されている。

## Notes

- For other repos, use `-R owner/repo` option
