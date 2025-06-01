# Rules

- When creating a PR: @~/.claude/rules/create-pr.md
- Do not revert changes with `git commit --amend`, `git reset --soft|hard`; keep the history linear and clear
- If pre-commit hooks fail or modify files, fix the issues and commit again using the original message
- Commit at logical checkpoints: one feature, one fix, or one coherent change per commit
- MUST add only relevant files to commits: use `git add <specific-file>` for each file. Never use `git add -A` or `git add .`
- GitHub access: Use `gh` command for all GitHub operations (avoid `gh api` subcommand). This includes handling GitHub URLs. Use `-R` option when accessing other repositories. (Purpose: `gh` commands are pre-approved for safe automatic execution)

# Code style

- Comments: English only, explain "why" not "what"
- Files: Must always end with a newline character to avoid "No newline at end of file" warnings
