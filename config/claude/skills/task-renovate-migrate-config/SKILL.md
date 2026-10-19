---
name: task-renovate-migrate-config
description: Batch process Renovate migrate-config PRs
---

# Batch process Renovate migrate-config PRs

Search for `renovate/migrate-config` branch PRs in fohte's GitHub repositories, filter those using `generic-boilerplate` (have `.copier-answers.yml`), and delegate migration work via delegate.

## Steps

1. Search PRs: `gh search prs "renovate/migrate-config" --owner=fohte --state=open`
2. Filter PRs with title "chore(config): migrate Renovate config"
3. Check `.copier-answers.yml` existence: `gh api repos/fohte/<repo>/contents/.copier-answers.yml`
4. List qualifying repositories
5. For each PR, write PR-specific details in a structured task file. Example:

```yaml
purpose: Renovate opened a configuration migration PR that needs review.
investigated: The PR is open and targets the configuration in example-owner/example-repo.
links:
    - https://github.com/example-owner/example-repo/pull/42
goal: Apply the migration and leave the PR ready for human review.
additionalContext: |
    Inspect the PR diff with `gh pr diff 42`.
    Run `npx --yes --package renovate -- renovate-config-validator --strict renovate.json5`.
    Do not merge the PR; a human will review and merge it.
```

Then use `delegate` to launch the task in a unique directory:

```bash
cd ~/ghq/github.com/fohte/<repo>
repo=$(git root -r)
dir=$(mktemp -d "$AGENT_TMPDIR/delegate.XXXXXX")
# Write the PR-specific task fields above to $dir/task.yaml.
# Keep the PR on its existing Renovate branch.
~/.agents/skills/delegate/scripts/launch \
  --task "$dir/task.yaml" --repo "$repo" \
  --branch renovate/migrate-config --label "Renovate PR #42 移行"
```

## Notes

- Include current repository (work in separate worktree)
- copier update is NOT needed
