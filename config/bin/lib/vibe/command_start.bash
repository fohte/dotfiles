#!/usr/bin/env bash
# Start command functions for vibe

parse_start_command() {
  if [[ "$#" -eq 0 ]]; then
    # Interactive mode: prompt for description and use Claude to generate name
    echo "What would you like to work on?"
    read -r description

    # Use Claude to generate a project name based on the description
    local claude_prompt="Based on this task description: \"${description}\", suggest a short, descriptive project name suitable for a git branch. The name should be lowercase, use hyphens instead of spaces, and be 2-4 words maximum. Output ONLY the suggested name, nothing else."

    local suggested_name
    suggested_name=$(echo "$claude_prompt" | claude --no-conversation 2> /dev/null)

    if [[ -z "$suggested_name" ]]; then
      error_exit "Failed to generate project name suggestion"
    fi

    echo "Suggested project name: $suggested_name"
    echo -n "Use this name? (Y/n): "
    read -r confirm

    if [[ "$confirm" =~ ^[Nn]$ ]]; then
      echo -n "Enter your preferred name: "
      read -r suggested_name
    fi

    echo "$suggested_name"
  elif [[ "$#" -eq 1 ]]; then
    echo "$1"
  else
    error_usage "'start' requires at most one argument"
  fi
}

handle_start() {
  local branch="$1"
  local worktree_path="$2"
  local worktree_dir="$3"
  local session_name="$4"
  local project_name="$5"

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
  start_claude_in_tmux "$session_name" "$window_name" "${worktree_path}" "$create_new_session"
}
