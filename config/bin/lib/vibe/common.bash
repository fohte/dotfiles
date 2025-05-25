#!/usr/bin/env bash
# Common utility functions for vibe

error_exit() {
  echo "error: $1" >&2
  exit 1
}

error_usage() {
  echo "error: $1" >&2
  usage
  exit 1
}

usage() {
  cat << EOF
Usage: $(basename "$0") <command> [<args>]

Commands:
  start <name>
    Start a new Claude Code session with worktree

  done [<name>] [--force|-f]
    Remove branch and worktree (only if merged)
    If <name> is omitted, uses current window name in vibe session
    Use --force or -f to skip merge check

vibe is a wrapper for Claude Code that:
  - Creates/enters a tmux session 'vibe'
  - Creates a git branch 'claude/<name>' from origin/master
  - Creates a worktree at '.worktrees/<name>'
  - Starts Claude Code in a new tmux window
EOF
}
