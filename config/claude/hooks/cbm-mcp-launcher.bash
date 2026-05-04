#!/bin/bash
# Wrapper for codebase-memory-mcp that pins the session to the main repo when
# launched from a git worktree. The MCP server derives its project name from
# CWD, so worktrees would otherwise produce a separate index per worktree.
# Trade-off: the graph reflects main HEAD, not the worktree's branch.
if root=$(git root -r 2> /dev/null); then
  cd "$root" || exit 1
fi
exec codebase-memory-mcp "$@"
