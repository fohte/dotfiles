# `vibe start` (delegate tasks to another Claude Code instance)

Run the `vibe start` command with some parameters to delegate processing to another Claude Code instance.

## How to use `vibe start`

`vibe start` is a command that creates a Claude Code execution environment.

### Basic usage

```bash
# Start with interactive name generation
vibe start <branch-name> -R <repo-name> -m <prompt>
```

- branch-name: Name of the branch to create for the new environment
- repo-name: Name of the repository where the new environment will be created (e.g. fohte/dotfiles)
- prompt: Instructions for the new Claude Code instance

## Important considerations for delegation

- Write specific instructions in the prompt
- Include context in the prompt so that a Claude Code instance with no prior knowledge can understand
