#!/usr/bin/env bash
# Start command functions for vibe

parse_start_command() {
  [[ "$#" -ne 1 ]] && error_usage "'start' requires exactly one argument"
  echo "$1"
}

handle_start() {
  local branch="$1"
  local worktree_path="$2"
  local worktree_dir="$3"
  local session_name="$4"
  local project_name="$5"
  local git_root="$6"

  # Check prerequisites
  check_branch_exists "${branch}" && error_exit "Branch '${branch}' already exists"
  [[ -d "${worktree_path}" ]] && error_exit "Worktree '${worktree_dir}' already exists"

  # Create branch and worktree
  create_branch_from_origin "${branch}"
  create_worktree "${worktree_path}" "${branch}"

  # Setup tmux
  local create_new_session=false
  tmux_session_exists "$session_name" || create_new_session=true

  # Extract name from branch
  local name="${branch#claude/}"
  local window_name="${project_name}-${name}"

  # Setup Claude project directory symlink before starting Claude Code
  # This needs git_root from the parent scope
  setup_claude_project_symlink "${worktree_path}" "${git_root}"

  start_claude_in_tmux "$session_name" "$window_name" "${worktree_path}" "$create_new_session"
}
