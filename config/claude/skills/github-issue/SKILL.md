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
4. Run `a ai draft <file-path>` to open in terminal + Neovim for user review
5. **STOP and wait for user approval.** Do NOT proceed to push until the user explicitly confirms. After `a ai draft`, use AskUserQuestion to ask the user if the content is ready to push. Never assume the user has finished reviewing just because the draft command returned.
6. Create the issue: `a gh issue-agent push ~/.cache/gh-issue-agent/<owner>/<repo>/new`
    - On success, the directory is renamed to `<issue-number>/`

#### Workflow C: Editing issue body/metadata

1. Pull the issue: `a gh issue-agent pull <issue-number>`
2. Edit `issue.md` or `metadata.json` in `~/.cache/gh-issue-agent/<owner>/<repo>/<issue-number>/`
3. Run `a ai draft <file-path>` to open the edited file in terminal + Neovim for user review
4. **STOP and wait for user approval.** Do NOT proceed to push until the user explicitly confirms. After `a ai draft`, use AskUserQuestion to ask the user if the content is ready to push. Never assume the user has finished reviewing just because the draft command returned.
5. After user approval, apply changes: `a gh issue-agent push <issue-number>`

#### Workflow D: Editing an EXISTING comment

Use this when the content should be added to or modified in an existing comment.

1. Pull the issue: `a gh issue-agent pull <issue-number>`
2. List comments: `ls ~/.cache/gh-issue-agent/<owner>/<repo>/<issue-number>/comments/`
3. Read the target comment file (identified from Step 1 analysis)
4. Edit the comment file directly
5. Run `a ai draft <file-path>` for user review
6. **STOP and wait for user approval.** Do NOT proceed to push until the user explicitly confirms. After `a ai draft`, use AskUserQuestion to ask the user if the content is ready to push. Never assume the user has finished reviewing just because the draft command returned.
7. Push changes: `a gh issue-agent push <issue-number>`

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
5. **STOP and wait for user approval.** Do NOT proceed to push until the user explicitly confirms. After `a ai draft`, use AskUserQuestion to ask the user if the content is ready to push. Never assume the user has finished reviewing just because the draft command returned.
6. Push changes: `a gh issue-agent push <issue-number>`

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
- **CRITICAL: After `a ai draft`, you MUST use AskUserQuestion to ask the user if the content is ready to push. NEVER proceed to `push` without explicit user confirmation.** The `a ai draft` command opens a file in Neovim for the user to review and edit. The command returning does NOT mean the user has finished reviewing. You must always ask and wait.

## Writing Style

Follow these guidelines when writing issues or comments:

- Issue body should only contain content aligned with the issue's purpose. For investigation issues, write "what to investigate", not the investigation results. Write results as separate comments
- Section headings should be concise. If the conclusion fits in a short heading, use a summary heading. Otherwise, use a simple heading (e.g., `## Cause`) and write the conclusion as the first sentence of the body
    - Bad: `Investigation Results`, `Symptoms` (too generic, says nothing about the content)
    - Good: `The 2 Pods returning 404 were in the proxy layer` (summary heading) or `## Cause` followed immediately by a one-sentence conclusion
- Write conclusions first. Put the conclusion as a single sentence immediately after the section heading. The reader wants to know the answer, not the process
    - Bad: `## Cause` followed by paragraphs explaining the investigation process, then finally the conclusion
    - Good: `## Cause` followed by `PR #123 introduced X, which caused Y.` as the first line, then supporting details below
- Structure content around the conclusion. Every piece of information should either be the conclusion itself, or directly support the conclusion. Before writing each section, ask: "does the reader need this to understand or believe the conclusion?" If not, it does not belong at the top level
    - Information that supports the conclusion (evidence, key data) → top level
    - Information that explains how the conclusion was reached but is not needed to understand it (mechanism details, timelines, process descriptions) → `<details>` block
    - Information the reader can derive from linked resources or execution logs → omit entirely
- Do not repeat information that is available at a link. If a PR or issue is linked, do not re-explain its contents in detail - the reader can follow the link. One-sentence summaries are sufficient
- Never use bold formatting. If text requires emphasis to be understandable, the structure or wording is the problem - fix that instead
- Do not write "next actions", "TODO", or "proposed next steps" sections unless the user explicitly asks. The reader decides what to do next
- Do not start list items with a summary followed by a colon. Write normal sentences instead
- When linking to external resources (e.g., other issues), explain why the link is relevant
- Use permalinks for GitHub source code links (include commit SHA instead of `main`/`master`)
    - Bad: `github.com/org/repo/blob/main/path/file.ts#L10`
    - Good: `github.com/org/repo/blob/abc123.../path/file.ts#L10`
    - Get latest commit SHA: `gh api -X GET repos/org/repo/commits -F path=<file> -F per_page=1 --jq '.[0].sha'`
- Use である調 (plain form), not ですます調 (polite form)
- Do not make recommendations or suggestions - only present facts and findings
- Do not write proposed solutions without verifying they actually work. For example, do not suggest "upgrade to a newer version" without confirming the issue is fixed in that version. Check upstream issues, release notes, and changelogs before proposing a fix
- Distinguish symptoms from root causes. "X is slow" or "there is a lag in Y" describes a symptom, not a cause. If the root cause is uncertain, use hedging language (e.g., "believed to be caused by")
- Do not include information unrelated to the issue's root cause in the proposed solutions or cause analysis, even if discovered during investigation
- Keep comments minimal. Only write what the reader needs to act on or understand the outcome. Do not add supplementary context that the reader can derive from the execution log or linked resources
- Place reference links inline where contextually relevant, not in a separate "References" section at the end
- Use numbered lists only when order matters (sequential steps, priority ranking); otherwise use bullet points
    - Bad: `1. Option A 2. Option B 3. Option C` (options have no inherent order)
    - Good: `- Option A - Option B - Option C`
- Issue titles must be specific about the problem - avoid vague words like "improvement" or "fix" without context
- When multiple problems share a root cause, consolidate them under that root cause rather than listing separately
- The What section should include proposed solutions, not just problem descriptions
- Titles should be abstract and concise - describe the essence of the work, not internal jargon or specific problem names
    - Bad: `Fix the "foobar bug" in config parser`
    - Good: `Update config parser`
- Check repository conventions before writing - use `view` on similar existing issues to match formatting (parent issue link placement, section structure, etc.)
- The What section should describe the strategic intent, not step-by-step procedures
    - Bad: `Remove line 42 from config.yaml`
    - Good: `Use the canonical config from the upstream repository`
- Completion criteria should describe the achieved state, not the work steps
    - Bad: `Delete the invalid entry from the file`
    - Good: `Changes are deployed to production`
- Parent issue references should be written as `- from <url>` list items within the Why section, not as a standalone `from:` line at the top of the issue body
    - Bad: issue 本文冒頭に `from: #491, #510` と書く
    - Good: Why セクション内で `- from #510` のようにリスト項目として書き、インデントで詳細を続ける

## Notes

- For other repos, use `-R owner/repo` option
