---
name: enable-vibe-coding
description: Start the user-requested autonomous implementation loop from a tq checklist through design review, PR merge, and the next delegation. Use when the user invokes /enable-vibe-coding or asks to run the implementation in vibe coding mode.
---

# Enable Vibe Coding

Run the implementation checklist as a sequence of delegated PRs. runok asks the user before `a agent vibe on`, which is the point where unattended PR merges become possible.

## Start

1. Resolve the tq task ID in this order: use `$ARGUMENTS` when supplied; otherwise use the current branch's `branch.<name>.x-tq-task-id` when set; otherwise use the unique leaf task linked to `$TQ_SESSION_ID` via `tq session list`. Reduce linked tasks to leaves with `jq`; if no single task remains, ask the user which task to run.
2. Resolve each leaf's target repository from its note. Delegate every leaf through a worktree and a PR, even when the repository's `repo.direct_commit` is `true`; the delegate skill's vibe rules cover this.
3. Pass your model name with `--author` on every `tq` command. Read the task with `tq task get <task-id>`. Require exactly one checklist named `実装` and read its leaves and notes. Read the task's design page with `tq page list` and `tq page get`; stop if there is no design page. Use `--output` and a unique `/tmp` path for a long page.
4. Confirm the `実装` checklist has at least one unchecked leaf. If every leaf is checked, report that the task is already complete and do not enable vibe mode.
5. Follow the `delegate` skill to prepare the prompts for every unchecked leaf whose `依存` note is resolved. Render each with `DELEGATE_VIBE=true` and `DELEGATE_TQ_CHECKLIST_ITEM_ID=<item-id>`. Before enabling vibe, confirm each rendered prompt contains the `## Vibe coding mode` section, and that `~/.agents/skills/create-pr/SKILL.md` defines both the `<vibe-draft-ready>` and `<vibe-pr-ready>` report formats. The delegate reads the report formats from `create-pr` and the item ID from the branch's `x-tq-checklist-item-id`, which `DELEGATE_TQ_CHECKLIST_ITEM_ID` sets, so the rendered prompt itself does not contain them. If any requirement is missing, stop and tell the user the installed skills do not support the required vibe reports yet. Keep the prepared payloads for dispatch; do not start delegates during this check.
6. Run `a agent vibe on` and confirm `a agent vibe status` succeeds. If either command fails, stop before delegating. The armyknife command may not be released in older installations.
7. Dispatch the prepared prompts in parallel through the `delegate` skill, passing the task ID and each leaf's checklist item ID through `a agent new`. For later newly ready leaves, perform the same rendered-prompt check before dispatch. Do not delegate parent items or leaves with unresolved dependencies.

Treat a dependency as resolved only when the referenced checklist work is checked and any stated release or merge requirement is satisfied. When a note has no dependency, or says `依存: なし`, the leaf is ready. If a dependency is ambiguous, leave that leaf undispatched until it can be verified.

## When a `<vibe-draft-ready>` report arrives

Handle each report once. A report must contain the absolute draft path, branch name, head SHA, checklist item ID, and the sentence `enable-vibe-coding skill の『draft ready を受けたら』の手順に従う`. Match the item ID to an active delegate and its task note. A default-branch CI repair has no checklist item; its report must identify that repair and include `checklist item ID: none`. Match it to the active repair delegate. If a report is malformed, ask the delegate to resend it in the `create-pr` format; if it does not match an active delegate, resolve it as described under `When something goes wrong`.

1. Confirm the reported head SHA exists in the target repository and is the tip of the reported branch. Read the draft from its absolute path and obtain the diff with `git diff origin/$(git main)...<head-sha>`. For a checklist PR, read the exact tq design page and item note. For a CI repair, use the failed run and repair task as the review context instead. Read `~/.agents/skills/create-pr/SKILL.md` and `~/.agents/skills/create-pr/references/draft-manual.md`. Run `~/.agents/skills/create-pr/scripts/render-rules` from the target repository root. If any required file or command is unavailable, stop as described under `Stop conditions`.
2. Ask a read-only subagent to review the draft as the user would in Step 3 of `create-pr`. Give it the draft, diff, applicable tq or CI repair context, `create-pr/SKILL.md`, `create-pr/references/draft-manual.md`, and the rendered rules; tell it to read the skill and reference. Require separate findings for PR content and design conformance, with concrete evidence. Tell the subagent not to edit files or interact with GitHub. Limit design review to whether the implementation follows the approved design; leave general code quality to the delegate's self-review.
3. If the PR body has findings, insert plain-language comments at the relevant places in the reported draft, as a reviewer would in the `a ai pr-draft review` editor. There is no special marker. Then notify the delegate that the draft contains comments and must be revised through the `create-pr` skill's Step 4. If the diff has findings, notify the delegate to fix the code. Include both sets of findings when both reviews fail. Do not approve the draft while either review has findings.
4. If both reviews pass, record the approved head SHA for this PR and notify the delegate that it is approved and may be submitted.

## When a `<vibe-pr-ready>` report arrives

A report must contain the PR URL, checklist item ID, and head SHA. For a CI repair, require `checklist item ID: none`. Match the report to the active delegate and its approved draft review. If a report is malformed, ask the delegate to resend it in the `create-pr` format; if it does not match an active delegate, resolve it as described under `When something goes wrong`.

1. Confirm that `gh pr view <pr> --json headRefOid -q .headRefOid` exactly matches the reported head SHA. If it does not, do not review or merge that report; ask the delegate for a fresh PR-ready report with the current SHA. Compare the reported SHA with the SHA approved during draft review. If they differ and the approved SHA is an ancestor of the reported SHA, obtain the incremental diff with `git diff <approved-sha>..<reported-head-sha>`. If the approved SHA is not an ancestor, the branch was rebased or rewritten; obtain the current PR-only diff with `git diff origin/$(git main)...<reported-head-sha>` and review that full diff against the design. Ask a read-only subagent to compare the applicable diff with the approved design page and item note, or the failed run and repair task for a CI repair. If the comparison has findings, notify the delegate to fix the code. If it passes, record the reported head SHA as approved.
2. Verify with `gh pr checks <pr>` that required checks are green. If checks are pending, wait for the delegate to finish them; do not merge yet. If a check failed, notify the delegate with the failed check and wait for a corrected ready report.
3. Confirm any required VRT approval is already present. If it is missing, stop and notify the user. Never add the `vrt-approved` label; visual review remains a human approval gate.
4. Immediately before merging, repeat `gh pr view <pr> --json headRefOid -q .headRefOid` and require an exact match with the approved SHA. If the SHA changed, do not merge; ask the delegate for a fresh PR-ready report and review the new changes. If the SHA still matches, required checks are green, and any required VRT approval is present, run `a gh pr-merge <pr>` from the target repository. Do not use `gh pr merge`.

## After a merge

1. Follow the `delegate` skill's merge procedure to confirm CI on the default branch is green. A merge notification for a PR this skill already merged is informational; do not process it as a new merge.
2. If default-branch CI fails, pause merges and new delegations. Notify active repository sessions to hold their merges, then delegate a CI repair through the `delegate` skill with `DELEGATE_VIBE=true`. Do not associate the repair with a checklist item. Review its draft and PR with the same draft-ready and PR-ready procedures, then check default-branch CI again. If the repair delegation fails, delegate another repair. Resume held sessions after CI is green.
3. Refresh `tq task get <task-id>` and confirm the merged checklist leaf is checked. If it remains unchecked, stop before redispatching that item and resolve the tq state.
4. Re-read the checklist. Dispatch every newly ready unchecked leaf in parallel, using the `Start` procedure's dependency rules. Keep already active delegates running.
5. Continue handling ready reports, merges, CI, and newly unblocked leaves until all leaves in `実装` are checked.

## When something goes wrong

Resolve these yourself and keep the loop running; do not ask the user.

- A delegate reports that a supplied premise is wrong: re-investigate, correct the premise (update the item note or design page when they were wrong), and notify the delegate with the correction.
- `a gh pr-merge` fails: for a conflict, tell the delegate to sync the base branch with the `sync-base-branch` skill; for a failed required check, tell the delegate to fix it; for any other failure, read the error and fix its cause or have the delegate fix it. Then handle its next PR-ready report.
- A report, PR, or delegate cannot be matched: identify it from `a agent peer children`, the branch's `x-tq-checklist-item-id`, and `gh pr list`, then continue.

## Stop conditions

- A required VRT approval is missing.
- A file or command required for draft review is unavailable.

When stopping, report the reason and the next decision needed to the user, then run `a agent status set you "<the decision needed, as a noun phrase>"`. Leave vibe mode on and wait for the user's direction. Do not continue merging or dispatching work while waiting.

When every leaf is checked, report completion to the user and run `a agent vibe off`.
