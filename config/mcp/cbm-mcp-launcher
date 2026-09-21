#!/bin/bash
# The server keys its index by CWD, so pin CWD to the main repo to keep one
# index across worktrees. The graph then reflects main HEAD, not the worktree's
# branch.
if root=$(git root -r 2> /dev/null); then
  cd "$root" || exit 1
fi
exec codebase-memory-mcp "$@"
