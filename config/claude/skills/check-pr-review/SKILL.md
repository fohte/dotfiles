---
name: check-pr-review
description: Use `a gh check-pr-review` to fetch and address PR review comments. Use this skill when checking PR review feedback, viewing unresolved threads, or addressing reviewer comments.
---

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
3. **Evaluate each comment** before making changes:
    - Consider whether the feedback should be addressed or not
    - If disagreeing with a comment, explain the reasoning to the user instead of making changes
    - Only proceed with code changes for feedback you agree with
4. Make necessary code changes based on the feedback
5. For "won't fix" comments, add a code comment near the relevant code explaining why the concern does not apply (e.g., `// executor_cmd is from the user's config file, not external input, so command injection is not a threat`)
6. If code changes were made (steps 4-5), commit and push using the `/commit` skill, then `git push`
7. **Reply to "won't fix" threads** on GitHub (see Reply to Review Threads below)
8. Re-run to verify all comments have been addressed

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

- **Language**: Match the language of the PR (Japanese PR → Japanese reply, English PR → English reply)
- **Tone**: Casual/plain style, no keigo (敬語). Bot reviewers don't need politeness
- **Length**: 1-2 sentences. Concise but complete
- Write **natural sentences** as a human would. No label prefixes like "Not applicable:", "対応不要:" at the start
- When citing evidence (versions, URLs, etc.), integrate them naturally into the sentence so the reader understands why they are mentioned. Don't drop bare values without context
- If the bot's claim is factually wrong, briefly explain **why** it is wrong, not just that it is wrong

**Do NOT**: write long explanations, include greetings/pleasantries, or quote the original comment back
