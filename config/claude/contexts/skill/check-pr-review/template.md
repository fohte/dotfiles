{{- $v := ds "vars" -}}
{{- $lang_override := eq $v.repo_language "ja" -}}
{{- $public := and (eq $v.repo.visibility "PUBLIC") (not $lang_override) -}}

# Check PR Review Comments

Fetch review comments for a PR and address any feedback.

## Usage

```bash
a gh pr-review check <pr-number> [-R <owner/repo>] [--all] [--review N] [--full]
```

## Options

- `-R <owner/repo>`: Target repository (default: current repo)
- `-a, --all`: Include resolved comments (default: only unresolved)
- `-r, --review N`: Show details for review number N
- `-f, --full`: Show all details (original behavior)
- `-d, --open-details`: Expand `<details>` blocks (default: collapsed)

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
2. **Automatically** run `--review N` for each review that has unresolved comments (do NOT ask the user if they want to see details)
3. **Evaluate each comment** with a **fix-by-default** mindset:
    - **Default action is to fix**: Assume review feedback is valid and should be addressed unless there is clear evidence otherwise
    - **"Won't fix" only for obvious false positives**: Only skip fixing when the reviewer's claim is factually incorrect (e.g., claims a version/API doesn't exist when it does, hallucinates non-existent issues, misreads the code logic)
    - **When unsure, ask the user**: If you're uncertain whether a comment is valid or how to address it, ask the user rather than deciding "won't fix" on your own
    - **Do NOT dismiss comments just because you disagree**: Reviewer suggestions about code style, safety, readability, or best practices should generally be followed even if the current code technically works
    - **NEVER autonomously decide "won't fix"**: Even if you believe a comment is a false positive, you MUST ask the user first. Do not skip this step under any circumstances. This is the most common mistake — always err on the side of asking
4. **Bug reports require test-first fixing**: When a review comment points out a bug (incorrect behavior, edge case failure, race condition, etc.), you MUST first write a test that reproduces the bug before fixing it. This ensures the bug is real and the fix is correct. Only after the test fails as expected, apply the code fix and confirm the test passes
5. Make necessary code changes based on the feedback
6. **User confirmation for "won't fix"**: Before treating any comment as "won't fix", you MUST ask the user for confirmation using AskUserQuestion. Present the reviewer's comment, your reasoning for why it's a false positive, and let the user decide whether to fix it or skip it. Never autonomously decide "won't fix" without user approval.
7. For confirmed "won't fix" comments (approved by the user in step 6), add a code comment near the relevant code explaining why the concern does not apply (e.g., `// executor_cmd is from the user's config file, not external input, so command injection is not a threat`)
8. If code changes were made (steps 4-7), commit and push using the `/commit` skill, then `git push`
   {{- if eq $v.repo.owner.login "fohte" }}
9. **Wait for Devin review after push**: After pushing, wait for Devin's review CI check to complete using `gh pr checks --watch`. Once the check passes, re-run `a gh pr-review check` to review Devin's feedback and address any new comments (repeat from step 1)
10. **Reply to "won't fix" threads and resolve addressed threads** using `a gh pr-review reply` (see Reply and Resolve Threads below)
11. Re-run to verify all comments have been addressed
    {{- else }}
12. **Reply to "won't fix" threads and resolve addressed threads** using `a gh pr-review reply` (see Reply and Resolve Threads below)
13. Re-run to verify all comments have been addressed
    {{- end }}

**Important**: After getting the summary, immediately proceed to fetch details for each review. Never ask the user "詳細を確認しますか?" or similar confirmation questions.

## Reply and Resolve Threads

After evaluating all comments and making code changes (if any), use `a gh pr-review reply pull`/`push` to reply to "won't fix" threads and resolve all addressed threads in a single workflow. Do NOT ask the user before replying. Do NOT reply to threads that were addressed with code changes.

### Step 1: Pull threads to local Markdown file

```bash
a gh pr-review reply pull <pr-number> [--include-resolved] [--force]
```

This fetches all unresolved threads to a local Markdown file at `$XDG_CACHE_HOME/gh-pr-review/<owner>/<repo>/<pr>/threads.md`.

### Step 2: Edit the Markdown file

The file contains threads in the following format:

<!-- prettier-ignore -->
```markdown
<!-- thread: RT_abc123 path: src/main.rs:42 -->
- [ ] resolve
<!-- diff -->
...
<!-- /diff -->
<!-- comment: @reviewer 2024-01-15T10:30:00Z -->
Review comment body
<!-- /comment -->
```

For each thread:

- **Threads addressed with code changes**: Change `- [ ] resolve` to `- [x] resolve`. Do NOT add a draft reply.
- **"Won't fix" threads**: Add a draft reply as plain text after the last `<!-- /comment -->` line, AND change `- [ ] resolve` to `- [x] resolve`.
- **Threads that should remain open**: Leave as-is.
- Do NOT resolve threads from Devin (Devin auto-resolves its own threads).

### Step 3: Review the edited file

Run `a ai review <file-path>` to open the threads file in terminal + Neovim for user review.

**STOP and wait for user approval.** Do NOT proceed to push until the user explicitly confirms. After `a ai review`, use AskUserQuestion to ask the user if the content is ready to push. Never assume the user has finished reviewing just because the command returned.

### Step 4: Push replies and resolutions to GitHub

```bash
a gh pr-review reply push <pr-number> [--dry-run] [--force]
```

Use `--dry-run` first to preview changes, then run without it to apply.

### Reply content guidelines

Replies are posted to bot reviewers (e.g., Gemini Code Assist).

{{ if $public -}}

- **Language**: Always reply in English
  {{- else -}}
- **Language**: Always reply in Japanese
  {{- end }}
- **Tone**: Casual/plain style, no keigo (敬語). Bot reviewers don't need politeness
- **Length**: 1-2 sentences. Concise but complete
- Write **natural sentences** as a human would. No label prefixes like "Not applicable:", "対応不要:" at the start
- When citing evidence (versions, URLs, etc.), integrate them naturally into the sentence so the reader understands why they are mentioned. Don't drop bare values without context
- If the bot's claim is factually wrong, briefly explain **why** it is wrong, not just that it is wrong
- **Inline code formatting**: Always wrap code tokens, commands, file paths, and similar technical terms in backticks (e.g., `COPY . .`, `docker build`, `/usr/local/bin`). Never write them as bare text

**Do NOT**: write long explanations, include greetings/pleasantries, quote the original comment back, or include links to external issues/PRs/URLs that the user did not explicitly ask to reference
