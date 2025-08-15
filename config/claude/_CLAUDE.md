# Rules

- You **MUST** follow these rules

## Use container-use

ALWAYS use ONLY Environments for ANY and ALL file, code, or shell operations—NO EXCEPTIONS—even for simple or generic requests.

DO NOT install or use the git cli with the environment_run_cmd tool. All environment tools will handle git operations for you. Changing ".git" yourself will compromise the integrity of your environment.

You MUST inform the user how to view your work using `container-use log <env_id>` AND `container-use checkout <env_id>`. Failure to do this will make your work inaccessible to others.

## Methodology

- Consult latest documentation using context7 MCP server for up-to-date library and framework information
- Focus on ensuring you are adding reminders and steps to research and understand the latest information from web search, parallel web search (very useful), and parallel agentic execution where possible.
- **Proactively use specialized sub-agents**: Always leverage Task tool with appropriate sub-agents for tasks matching their expertise, and launch multiple agents in parallel when tasks are independent
- Maximize productivity through parallel execution using sub-agents:
  - Launch multiple Task sub-agents concurrently for independent research/analysis tasks
  - Break down complex tasks into atomic, self-contained units that can execute in parallel
  - Batch tool calls (e.g., multiple file reads, searches) in single messages for concurrent execution
  - Ensure each parallel task has sufficient context to operate autonomously
  - Use MECE (Mutually Exclusive, Collectively Exhaustive) task decomposition for optimal parallelization

### Todo Granularity Guidelines

Create todos only for:
- **Meaningful deliverables**: Features, integrations, or capabilities that can be independently verified
- **Research/decisions**: Tasks that produce architectural decisions or technology choices
- **Significant artifacts**: Creating workflows, documentation, or major code components
- **Integration milestones**: Points where systems connect and need verification

Do NOT create todos for:
- **Configuration updates**: Setting IDs, tokens, or environment variables
- **Single commands**: Running tests, builds, or deployments locally
- **Implementation details**: Steps that are naturally part of completing a larger task
- **Routine operations**: Standard development activities like committing code or updating dependencies

### When to Mark Todos as Done

Todos are done when the deliverable is **shipped**, not just implemented:
- Code changes → PR merged
- Decisions → Documented and shared
- Integrations → Working in production
- Features → Deployed and verified

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
