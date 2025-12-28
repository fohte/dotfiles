---
name: delegate-claude
description: Use this skill to delegate tasks to another Claude Code instance in a separate worktree. Use when you want to offload work to run in parallel without blocking the current session.
---

# Delegate tasks to another Claude Code instance

Use `git wm new --prompt` to delegate processing to another Claude Code instance in a separate worktree.

## How to use

```bash
git wm new <branch-name> --prompt "<instructions>"
```

- `branch-name`: Name of the branch to create for the new environment
- `--prompt`: Instructions for the new Claude Code instance

### Examples

```bash
# Current repository
git wm new feature-login --prompt "Implement login functionality with email/password authentication"

# Different repository
cd ~/ghq/github.com/fohte/other-repo && git wm new feature-x --prompt "Implement feature X"
```

This will:

1. Create a new git worktree with the specified branch
2. Open a new tmux window with Neovim and Claude Code
3. Automatically send the prompt to Claude Code

## Important considerations for delegation

- **Branch naming**: Do NOT include `/` in branch names. Use hyphens instead (e.g., `fix-login-bug` not `fix/login-bug`). The branch will be prefixed with `fohte/`, so `fix/...` would create `fohte/fix/...` which is redundant.
- Write specific, self-contained instructions in the prompt
- Include all necessary context so that a Claude Code instance with no prior knowledge can understand the task
- The new instance will work in an isolated worktree, so changes won't conflict with your current work
