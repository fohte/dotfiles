# Rules

- When creating a PR: @~/.claude/rules/create-pr.md
- Do not use `git commit --amend`; keep the history linear and clear
- If pre-commit hooks fail or modify files, fix the issues and commit again using the original message
- Commit at logical checkpoints: one feature, one fix, or one coherent change per commit

# Code style

- Comments: English only, explain "why" not "what"
- Files: Must always end with a newline character to avoid "No newline at end of file" warnings
