# Batch process Renovate migrate-config PRs

Search for `renovate/migrate-config` branch PRs in fohte's GitHub repositories, filter those using `generic-boilerplate` (have `.copier-answers.yml`), and delegate migration work via delegate-claude.

## Steps

1. Search PRs: `gh search prs "renovate/migrate-config" --owner=fohte --state=open`
2. Filter PRs with title "chore(config): migrate Renovate config"
3. Check `.copier-answers.yml` existence: `gh api repos/fohte/<repo>/contents/.copier-answers.yml`
4. List qualifying repositories
5. For each repository, use `delegate-claude` Skill:

```bash
cd ~/ghq/github.com/fohte/<repo> && a wm new renovate/migrate-config --prompt "## Background
Renovate created a config migration PR #<number>.

## Task
1. Check PR diff: gh pr diff <number>
2. Investigate what migration is needed
3. Make necessary changes and push to make the PR ready for merge
4. Validate config: npx --yes --package renovate -- renovate-config-validator --strict renovate.json5
   - The --strict flag fails if migration is still needed
   - Ensure validation passes before finishing

## Important
- Do NOT merge the PR. Human will review and merge manually."
```

## Notes

- Include current repository (work in separate worktree)
- copier update is NOT needed
