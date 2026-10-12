---
name: enable-vibe-coding
description: Start the user-requested autonomous implementation loop from a tq checklist through design review, PR merge, and the next delegation. Use only when the user explicitly invokes /enable-vibe-coding.
disable-model-invocation: true
---

# Enable Vibe Coding

Run the implementation checklist as a sequence of delegated PRs. The user must invoke this skill explicitly because it enables unattended PR merges.

## Start

1. Resolve the tq task ID in this order: use `$ARGUMENTS` when supplied; otherwise use the current branch's `branch.<name>.x-tq-task-id` when set; otherwise use the unique leaf task linked to `$TQ_SESSION_ID` via `tq session list`. Reduce linked tasks to leaves with `jq`; if no single task remains, ask the user which task to run.
2. Resolve the repository root with `git root -r`, then read its armyknife setting with `a config get repo.direct_commit`. Stop if the value is `true`; this workflow requires PRs. Stop if the setting cannot be read or is not exactly `false`.
3. Pass your model name with `--author` on every `tq` command. Read the task with `tq task get <task-id>`. Require exactly one checklist named `実装` and read its leaves and notes. Read the task's design page with `tq page list` and `tq page get`; stop if there is no design page. Use `--output` and a unique `/tmp` path for a long page.
4. Confirm the `実装` checklist has at least one unchecked leaf. If every leaf is checked, report that the task is already complete and do not enable vibe mode.
5. Follow the `delegate` skill to prepare the prompts for every unchecked leaf whose `依存` note is resolved. Render each with `DELEGATE_VIBE=true` and `DELEGATE_TQ_CHECKLIST_ITEM_ID=<item-id>`. Before enabling vibe, confirm each rendered prompt contains `<vibe-pr-ready>`, that leaf's item ID, and `enable-vibe-coding skill の「PR ready を受けたら」の手順に従う`. If any marker is missing, stop and tell the user the installed delegate prompt does not support vibe reports yet. Keep the prepared payloads for dispatch; do not start delegates during this check.
6. Run `a agent vibe on` and confirm `a agent vibe status` succeeds. If either command fails, stop before delegating. The armyknife command may not be released in older installations.
7. Dispatch the prepared prompts in parallel through the `delegate` skill, passing the task ID and each leaf's checklist item ID through `a agent new`. For later newly ready leaves, perform the same rendered-prompt check before dispatch. Do not delegate parent items or leaves with unresolved dependencies.

Treat a dependency as resolved only when the referenced checklist work is checked and any stated release or merge requirement is satisfied. When a note has no dependency, or says `依存: なし`, the leaf is ready. If a dependency is ambiguous, leave that leaf undispatched until it can be verified.

## When a `<vibe-pr-ready>` report arrives

Handle each report once. A checklist PR report must contain the PR URL, the checklist item ID, and the sentence `enable-vibe-coding skill の「PR ready を受けたら」の手順に従う`. Match the item ID to an active delegate and its task note. A default-branch CI repair has no checklist item; its report must identify that repair and include `checklist item ID: none`. Match it to the active repair delegate. If a report is malformed or does not match an active delegate, stop and notify the user.

1. Verify with `gh pr checks <pr>` that the PR's checks are green. If checks are pending, wait for the delegate to finish them; do not review or merge yet. If a check failed, notify the delegate with the failed check and wait for a corrected ready report.
2. Obtain the PR diff, title, and body from the target repository. Read the exact tq design page and the item's note. Run `~/.agents/skills/create-pr/scripts/render-rules` from the target repository root to get the current PR rules. If the command fails, stop and notify the user.
3. Ask a read-only subagent to review the diff against the design page and item note, and to review the PR title and body against the rendered create-pr rules. Give it the PR diff, title, body, design page, item note, and rendered rules. For a CI repair, use the failed run and repair task in place of the checklist note. Require separate findings for design conformance and PR content conformance, each with concrete evidence. Tell the subagent not to edit files or interact with GitHub. Limit design review to whether the implementation follows the approved design; leave general code quality to the delegate's self-review.
4. If both reviews pass, run `a gh pr-merge <pr>` from the target repository. Do not use `gh pr merge`. Never add the `vrt-approved` label; visual review remains a human approval gate.
5. If either review fails, notify the matching delegate with the findings and ask it to revise and resubmit. For PR body findings, tell it to write the comments into its draft and follow Step 4 of the `create-pr` skill. Count review failures per PR. If the same PR fails review twice, stop and notify the user.

## After a merge

1. Follow the `delegate` skill's merge procedure to confirm CI on the default branch is green. A merge notification for a PR this skill already merged is informational; do not process it as a new merge.
2. If default-branch CI fails, pause merges and new delegations. Notify active repository sessions to hold their merges, then delegate a CI repair through the `delegate` skill with `DELEGATE_VIBE=true`. Do not associate the repair with a checklist item. Review its PR using the same ready-report procedure, then check default-branch CI again. If the repair delegation fails, stop and notify the user. Resume held sessions after CI is green.
3. Refresh `tq task get <task-id>` and confirm the merged checklist leaf is checked. If it remains unchecked, stop before redispatching that item and resolve the tq state.
4. Re-read the checklist. Dispatch every newly ready unchecked leaf in parallel, using the `Start` procedure's dependency rules. Keep already active delegates running.
5. Continue handling ready reports, merges, CI, and newly unblocked leaves until all leaves in `実装` are checked.

## Stop conditions

- The same PR fails design or PR body review twice.
- A delegate reports that a supplied premise is wrong.
- `a gh pr-merge` fails, including a conflict or failed required check.
- The delegated default-branch CI repair fails.
- A required VRT approval is missing, or the checklist, PR, or delegate cannot be identified safely.

When stopping, send a PushNotification explaining the reason and the next decision needed, then run `a agent status set decide`. Leave vibe mode on and wait for the user's direction. Do not continue merging or dispatching work while waiting.

When every leaf is checked, report completion to the user and run `a agent vibe off`.
