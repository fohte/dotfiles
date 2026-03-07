{{- $v := ds "vars" -}}
{{- $lang_override := eq $v.repo_language "ja" -}}
{{- $public := and (eq $v.repo.visibility "PUBLIC") (not $lang_override) -}}

# Check PR Review Comments

Fetch review comments for a PR and address any feedback.

## Usage

```bash
a gh check-pr-review <pr-number> [-R <owner/repo>] [--all] [--review N] [--full]
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
4. **Bug reports require test-first fixing**: When a review comment points out a bug (incorrect behavior, edge case failure, race condition, etc.), you MUST first write a test that reproduces the bug before fixing it. This ensures the bug is real and the fix is correct. Only after the test fails as expected, apply the code fix and confirm the test passes
5. Make necessary code changes based on the feedback
6. **User confirmation for "won't fix"**: Before treating any comment as "won't fix", you MUST ask the user for confirmation using AskUserQuestion. Present the reviewer's comment, your reasoning for why it's a false positive, and let the user decide whether to fix it or skip it. Never autonomously decide "won't fix" without user approval.
7. For confirmed "won't fix" comments (approved by the user in step 6), add a code comment near the relevant code explaining why the concern does not apply (e.g., `// executor_cmd is from the user's config file, not external input, so command injection is not a threat`)
8. If code changes were made (steps 4-7), commit and push using the `/commit` skill, then `git push`
9. **Reply to "won't fix" threads** on GitHub (see Reply to Review Threads below)
10. **Resolve all addressed threads** from bot reviewers (see Resolve Review Threads below)
11. Re-run to verify all comments have been addressed

**Important**: After getting the summary, immediately proceed to fetch details for each review. Never ask the user "詳細を確認しますか?" or similar confirmation questions.

## Reply to Review Threads

After evaluating all comments and making code changes (if any), reply to each thread that was deemed **"won't fix" / not applicable**. Do NOT ask the user before replying. Do NOT reply to threads that were addressed with code changes.

### Step 1: Fetch comment IDs

The `a gh check-pr-review` output does not include comment IDs. Fetch them separately:

```bash
gh api -X GET "repos/{owner}/{repo}/pulls/{pr_number}/comments" --jq '.[] | {id, path, line, body: .body[:80], in_reply_to_id, user: .user.login}'
```

Match each "won't fix" thread (by file path, line number, and comment body) to its comment ID. Reply to the **root comment** of each thread (the one without `in_reply_to_id`).

### Step 2: Post replies

```bash
gh api -X POST "repos/{owner}/{repo}/pulls/{pr_number}/comments/{comment_id}/replies" -f body="reply text"
```

**CRITICAL**: The API path MUST include `pulls/{pr_number}`. The shorter path `repos/{owner}/{repo}/pulls/comments/{comment_id}/replies` returns 404.

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

**Do NOT**: write long explanations, include greetings/pleasantries, or quote the original comment back

## Resolve Review Threads (Gemini Code Assist)

After addressing all comments (both code fixes and "won't fix" replies), **resolve every thread** from bot reviewers (e.g., Gemini Code Assist). Bot reviewers cannot resolve their own threads, so this must be done manually. Do NOT resolve threads from Devin, as Devin auto-resolves its own threads.

Resolve threads for **both** cases:

- Threads where code changes were made
- Threads where a "won't fix" reply was posted

**IMPORTANT**: Claude Code's Bash tool escapes `!` to `\!`, which breaks GraphQL's Non-Null type modifier (e.g., `String!` becomes `String\!`). Therefore, **never use GraphQL variables** (`$owner: String!`, etc.). Always inline literal values directly into the query string.

### Step 1: Fetch unresolved thread IDs

```bash
gh api graphql -f query='query { repository(owner: "{owner}", name: "{repo}") { pullRequest(number: {pr_number}) { reviewThreads(first: 100) { nodes { id isResolved comments(first: 1) { nodes { body author { login } } } } } } } }' --jq '.data.repository.pullRequest.reviewThreads.nodes[] | select(.isResolved == false) | {id, author: .comments.nodes[0].author.login, body: .comments.nodes[0].body[:80]}'
```

Filter to only Gemini Code Assist threads from the results.

### Step 2: Resolve threads

Use a `for` loop with the thread IDs from Step 1:

```bash
for thread_id in {thread_id_1} {thread_id_2} ...; do
  gh api graphql -f query='mutation { resolveReviewThread(input: {threadId: "'"$thread_id"'"}) { thread { id } } }'
done
```

Replace `{thread_id_1} {thread_id_2} ...` with the actual thread IDs from Step 1. Only resolve threads that were addressed in this session.
