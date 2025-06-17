# Rules

- You **MUST** follow these rules

## Methodology

- Always formalize the plan for next steps using sequential-thinking, context7 MCP servers, and get user confirmation before proceeding with implementation
- Focus on ensuring you are adding reminders and steps to research and understand the latest information from web search, parallel web search (very useful), and parallel agentic execution where possible.
- Maximize productivity through parallel execution using sub-agents:
  - Launch multiple Task sub-agents concurrently for independent research/analysis tasks
  - Break down complex tasks into atomic, self-contained units that can execute in parallel
  - Batch tool calls (e.g., multiple file reads, searches) in single messages for concurrent execution
  - Ensure each parallel task has sufficient context to operate autonomously
  - Use MECE (Mutually Exclusive, Collectively Exhaustive) task decomposition for optimal parallelization

## Repository Access

- GitHub repositories are available for research and analysis in the `~/ghq` directory
- User's repositories: Located at `~/ghq/github.com/fohte/<repo-name>`
- External repositories: Clone using `ghq get <org>/<repo-name>` to make them available for analysis

## Workflow

- Do not revert changes with `git commit --amend`, `git reset --soft|hard`; keep the history linear and clear
- If pre-commit hooks fail or modify files, fix the issues and commit again using the original message
- Commit at logical checkpoints: one feature, one fix, or one coherent change per commit
- GitHub access: Use `gh` command for all GitHub operations (avoid `gh api` subcommand). This includes handling GitHub URLs. Use `-R` option when accessing other repositories. (Purpose: `gh` commands are pre-approved for safe automatic execution)
- File deletion: Use `git rm` instead of `rm` when deleting tracked files to properly stage the deletion
- Temporary files: Use `.claude/tmp/` directory for any temporary files as it is ignored by git

## Code style

- Comments: English only, explain "why" not "what"
- Files: Must always end with a newline character to avoid "No newline at end of file" warnings
