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
- The new instance will work in an isolated worktree, so changes won't conflict with your current work

## Prompt structure (REQUIRED)

The delegated Claude Code instance has **no prior knowledge** of the current conversation. You MUST include sufficient context in the prompt using the following structure:

```
## Background
[Why this task is needed. What problem are we solving? What is the motivation?]

## Current situation
[What is the current state? Any relevant decisions already made? Related files or code?]

## Task
[Specific instructions for what to implement/fix/investigate]

## Expected outcome
[What should be the result? How to verify success?]

## Constraints (if any)
[Any limitations, dependencies, or requirements to be aware of]
```

### Example: Good prompt

```bash
git wm new fix-auth-timeout --prompt "## Background
Users are experiencing session timeouts after 5 minutes of inactivity, but the expected timeout is 30 minutes.

## Current situation
- Authentication is handled in src/auth/session.ts
- Session config is in config/auth.json
- We recently migrated from JWT to session-based auth

## Task
1. Investigate why sessions expire after 5 minutes
2. Fix the timeout configuration
3. Add a test to verify 30-minute timeout

## Expected outcome
Sessions should persist for 30 minutes of inactivity. Tests should pass.

## Constraints
- Do not change the session storage mechanism (Redis)
- Maintain backward compatibility with existing sessions"
```

### Example: Bad prompt (insufficient context)

```bash
# DON'T do this - the new instance won't know what "the bug" or "as discussed" means
git wm new fix-bug --prompt "Fix the bug we discussed earlier"
```
