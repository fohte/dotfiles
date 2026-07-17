{{- $v := ds "vars" -}}
{{- $lang_override := eq $v.repo_language "ja" -}}
{{- $public := and (eq $v.repo.visibility "PUBLIC") (not $lang_override) -}}
{{- $owner_fohte := eq $v.repo.owner.login "fohte" -}}
{{- $bot_examples := "CodeRabbit, Devin" -}}

# Check PR Review Comments

{{- if $owner_fohte }}

fohte 個人リポジトリには自動レビュー bot も人間レビューも存在しない。
このスキルは **no-op**: 以下の手順は一切実行せず、ユーザーに no-op である旨だけ伝えて終了する。
{{- else }}

Fetch review comments for a PR and address any feedback.

## Usage

```bash
a gh pr-review reply pull <pr-number> [-R <owner/repo>] [--include-resolved] [--force]
```

This pulls all review threads (and review bodies like "LGTM!") to a local Markdown file at `$XDG_CACHE_HOME/armyknife/gh-pr-review/<owner>/<repo>/<pr>/threads.md`. Read that file directly to see review feedback. Diff hunks are auto-compressed (commented line + 5 before / 3 after) and `<details>` blocks are folded by default.

## Options

- `-R <owner/repo>`: Target repository (default: current repo)
- `--include-resolved`: Include resolved threads (default: only unresolved)
- `--force`: Overwrite local edits without confirmation
- `-d, --open-details`: Expand `<details>` blocks (default: folded)

## Workflow

1. **Wait for bot reviewers to finish before pulling**: Right after creating or pushing to a PR, automated reviewers ({{ $bot_examples }}, etc.) have not yet posted comments. Pulling immediately will return zero threads and miss feedback. Run `a ai review wait <pr>` in the background (`run_in_background: true`) and wait for the `<task-notification>` completion event before proceeding. Do NOT poll the output file or sleep — only the completion notification is allowed. Skip this wait only when the user is asking to re-check a PR that has been idle for some time (i.e., bot reviews already finished in a previous turn).
2. Run `a gh pr-review reply pull <pr>` (use `--force` when overwriting prior local edits) and Read the resulting file
3. **Evaluate each comment** with a **fix-by-default** mindset:
    - **Default action is to fix**: Assume review feedback is valid and should be addressed unless there is clear evidence otherwise
    - **"Won't fix" only for obvious false positives**: Only skip fixing when the reviewer's claim is factually incorrect (e.g., claims a version/API doesn't exist when it does, hallucinates non-existent issues, misreads the code logic)
    - **When unsure, ask the user**: If you're uncertain whether a comment is valid or how to address it, ask the user rather than deciding "won't fix" on your own
    - **Do NOT dismiss comments just because you disagree**: Reviewer suggestions about code style, safety, readability, or best practices should generally be followed even if the current code technically works
    - **NEVER autonomously decide "won't fix"**: Even if you believe a comment is a false positive, you MUST ask the user first. Do not skip this step under any circumstances. This is the most common mistake — always err on the side of asking
4. **Bug reports require test-first fixing**: When a review comment points out a bug (incorrect behavior, edge case failure, race condition, etc.), you MUST first write a test that reproduces the bug before fixing it. This ensures the bug is real and the fix is correct. Only after the test fails as expected, apply the code fix and confirm the test passes
5. Make necessary code changes based on the feedback
6. **User confirmation for "won't fix"**: Before treating any comment as "won't fix", you MUST ask the user for confirmation. The user can only make a real decision when they can see the same evidence you used, so the explanation goes in the assistant message **before** the AskUserQuestion call — not crammed into option labels. Never autonomously decide "won't fix" without user approval.

    For each "won't fix" candidate, write out these three elements as separate, labeled bullets in the message text:
    - **What the reviewer flagged**: the substance of the comment in plain language — what behavior, file, or line is being criticized, and what change the reviewer proposes
    - **Why the reviewer flagged it**: the reviewer's premise or reasoning, including any assumption they made (e.g., "the reviewer saw only the diff and inferred X is missing")
    - **Why "won't fix" is justified**: the concrete evidence (file paths, line numbers, upstream design choices, factual corrections to the reviewer's premise) that makes the comment a false positive or out of scope

    AskUserQuestion then offers the decision (fix / won't fix / something else). Option `description` fields stay short — they are not a substitute for the three-element explanation above. A one-line summary like "両方とも boilerplate-managed" is not enough; if the user has to ask "what was the comment about?" the message is too thin.

7. For confirmed "won't fix" comments (approved by the user in step 6), add a code comment near the relevant code explaining why the concern does not apply (e.g., `// executor_cmd is from the user's config file, not external input, so command injection is not a threat`)
8. If code changes were made (steps 4-7), commit and push using the `/commit` skill, then `git push`
9. **Reply to "won't fix" threads and resolve addressed threads** using `a gh pr-review reply` (see Reply and Resolve Threads below)
10. Re-run from step 1 to verify all comments have been addressed (step 1's wait covers the post-push reviewer round-trip as well)

## Reply and Resolve Threads

After evaluating all comments and making code changes (if any), edit the threads file pulled in step 1, then submit the replies. Do NOT ask the user before replying.

### Step 1: Edit the Markdown file

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

- **Reply position (applies to every thread type below)**: Draft replies MUST be written as plain text on a new line **after the thread's last `<!-- /comment -->` line**. Never insert the reply between `<!-- thread: ... -->` and `<!-- diff -->`, or directly under the `- [ ] resolve` / `- [x] resolve` line — that position belongs to the checkbox only and the reply will not be picked up correctly.
- **Threads addressed with code changes**: Change `- [ ] resolve` to `- [x] resolve`, then append a draft reply `Fixed in <commit-hash>.` after the last `<!-- /comment -->` line, where `<commit-hash>` is the short hash of the commit that addressed the comment. If the fix involved additional context worth mentioning, append a brief explanation after the period (e.g., `Fixed in abc1234. Switched to using X instead of Y as suggested.`).
- **"Won't fix" threads**: Change `- [ ] resolve` to `- [x] resolve`, then append a draft reply after the last `<!-- /comment -->` line explaining why the concern does not apply.
- **Threads that should remain open**: Leave as-is.
- Do NOT resolve threads from Devin (Devin auto-resolves its own threads).

Example of the correct reply position:

<!-- prettier-ignore -->
```markdown
<!-- thread: RT_abc123 path: src/main.rs:42 -->
- [x] resolve
<!-- diff -->
...
<!-- /diff -->
<!-- comment: @reviewer 2024-01-15T10:30:00Z -->
Review comment body
<!-- /comment -->
Fixed in abc1234. Switched to using X as suggested.
```

### Step 2: Review the edited file

Run `a gh pr-review reply review <pr-number>` **in background** (`run_in_background: true`) to open the threads file in terminal + Neovim for user review. This command blocks until the user closes the editor, so it will complete when the user finishes reviewing.

**STOP and wait for the background command to complete.** Do NOT proceed to push until the command finishes. When it completes, check the exit code: exit code 0 means the user approved the draft, exit code 1 means not approved (user closed without approving), exit code 2 means the editor is already open, exit code 3 means the terminal emulator failed to launch within 10s (likely macOS is asleep). If not approved, ask the user what to change. If already open (exit code 2), inform the user that the editor is already open and they can reload the file in their editor (e.g., `:e` in Neovim). Do NOT retry the command. If the terminal failed to launch (exit code 3), no lock file is left behind — tell the user the terminal could not start (likely macOS asleep) and ask them to retry once it is available. Do NOT auto-retry; the same condition will fail again until the user resolves it.

**On exit, the command writes a unified diff of any user edits to stdout.** Read that diff directly to see what the user changed — do NOT re-Read the threads file to find the changes.

**NEVER edit the `submit:` frontmatter field yourself.** The `submit: true` flag represents the human reviewer's approval of the drafted replies. It MUST only be set by the user via the `reply review` workflow (Step 2). Do not flip `submit: false` to `submit: true` to bypass the editor step, even if `push` fails with "File has been modified after approval". If approval is invalidated, re-run `reply review` and let the user re-approve — never edit the frontmatter to shortcut the flow.

### Step 3: Push replies and resolutions to GitHub

```bash
a gh pr-review reply push <pr-number> [--dry-run] [--force]
```

Use `--dry-run` first to preview changes, then run without it to apply.

### Reply content guidelines

Replies are posted to bot reviewers (e.g., {{ $bot_examples }}).

{{ if $public -}}

- **Language**: Always reply in English
  {{- else -}}
- **Language**: Always reply in Japanese
  {{- end }}
- **Tone**: Bot reviewers don't need politeness, so skip keigo (敬語). Japanese replies must use 常体 (だ・である調) in written-language register. Spoken-language contractions and casual sentence-end particles (e.g., 「含まれてる」「思う」「だよ」「〜ね」「〜じゃん」) are forbidden — they read as sloppy in a written technical context. Use the dictionary form instead: 「含まれている」「と思われる」「である」
- **Length**: 1-2 sentences. Concise but complete
- Write **natural sentences** as a human would, but treat the reply as written technical prose, not chat. No label prefixes like "Not applicable:", "対応不要:" at the start
- When citing evidence (versions, URLs, etc.), integrate them naturally into the sentence so the reader understands why they are mentioned. Don't drop bare values without context
- If the bot's claim is factually wrong, briefly explain **why** it is wrong, not just that it is wrong
- **Inline code formatting**: Always wrap code tokens, commands, file paths, and similar technical terms in backticks (e.g., `COPY . .`, `docker build`, `/usr/local/bin`). Never write them as bare text
- **Fixed replies must include commit hash**: When replying to a thread that was addressed with a code change, always include the commit hash (e.g., `Fixed in abc1234.`). Never reply with just "Fixed." or similar without a hash

**Do NOT**: write long explanations, include greetings/pleasantries, praise the reviewer (e.g., "Good catch!", "Great suggestion!", "Thanks for pointing this out!"), quote the original comment back, or include links to external issues/PRs/URLs that the user did not explicitly ask to reference. Reviewers are bots — complimenting them is meaningless and looks unnatural
{{- end }}
