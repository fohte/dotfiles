#!/usr/bin/env bash
# List command functions for vibe

parse_list_command() {
  # No arguments expected for list command
  if [[ "$#" -ne 0 ]]; then
    error_usage "'list' takes no arguments"
  fi
}

handle_list() {
  local git_root="$1"
  local project_name="$2"
  local session_name="$3"

  # Get all vibe branches (claude/*)
  local branches
  branches=$(git branch --list 'claude/*' --format='%(refname:short)' 2> /dev/null) || {
    echo "No active vibe sessions found."
    return 0
  }

  # Filter out empty results
  branches=$(echo "$branches" | grep -v '^$' || true)

  if [[ -z "$branches" ]]; then
    echo "No active vibe sessions found."
    return 0
  fi

  # Check if tmux session exists
  local tmux_available=false
  if tmux_session_exists "$session_name"; then
    tmux_available=true
  fi

  # Collect all data first, then format with column
  local table_data=""
  table_data="NAME\tBRANCH\tPR\tDIRECTORY\tSESSION"

  # List each vibe session with status
  while IFS= read -r branch; do
    [[ -z "$branch" ]] && continue

    local name="${branch#claude/}"
    local worktree_dir=".worktrees/${name}"
    local worktree_path="${git_root}/${worktree_dir}"
    local window_name="${project_name}-${name}"

    # Check if worktree exists
    local worktree_status="NO"
    if [[ -d "$worktree_path" ]]; then
      worktree_status="YES"
    fi

    # Check if tmux window exists
    local tmux_status="NO"
    if [[ "$tmux_available" == "true" ]] && tmux_window_exists "$session_name" "$window_name"; then
      tmux_status="YES"
    fi

    # Check PR merge status
    local pr_status
    if check_pr_merged "${branch}"; then
      pr_status="MERGED"
    elif is_branch_merged "${branch}"; then
      pr_status="MERGED"
    else
      pr_status="OPEN"
    fi

    # Format directory and session status (plain text for column)
    local directory_status session_status
    if [[ "$worktree_status" == "YES" ]]; then
      directory_status="Active"
    else
      directory_status="Missing"
    fi

    if [[ "$tmux_status" == "YES" ]]; then
      session_status="Running"
    else
      session_status="Stopped"
    fi

    # Add row to table data
    table_data="$table_data\n$name\t$branch\t$pr_status\t$directory_status\t$session_status"
  done <<< "$branches"

  # Output formatted table with colors applied after column alignment
  echo -e "$table_data" | column -t | while IFS= read -r line; do
    if [[ "$line" == "NAME"* ]]; then
      # Header row - make it bold
      echo -e "\033[1m$line\033[0m"
    else
      # Data row - apply colors to specific fields
      echo "$line" | sed \
        -e 's/MERGED/\x1b[32mMERGED\x1b[0m/' \
        -e 's/OPEN/\x1b[33mOPEN\x1b[0m/' \
        -e 's/Active/\x1b[32mActive\x1b[0m/' \
        -e 's/Missing/\x1b[31mMissing\x1b[0m/' \
        -e 's/Running/\x1b[32mRunning\x1b[0m/' \
        -e 's/Stopped/\x1b[31mStopped\x1b[0m/'
    fi
  done
}
