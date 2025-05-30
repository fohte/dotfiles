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

  echo -e "\033[1mNAME        BRANCH              PR      DIRECTORY   SESSION\033[0m"

  # Check if tmux session exists
  local tmux_available=false
  if tmux_session_exists "$session_name"; then
    tmux_available=true
  fi

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

    # Check PR merge status with colors
    local pr_status pr_color
    if check_pr_merged "${branch}"; then
      pr_status="MERGED"
      pr_color="\033[32m" # green
    elif is_branch_merged "${branch}"; then
      pr_status="MERGED"
      pr_color="\033[32m" # green
    else
      pr_status="OPEN"
      pr_color="\033[33m" # yellow
    fi

    # Format directory and session status with icons
    local directory_status session_status
    if [[ "$worktree_status" == "YES" ]]; then
      directory_status="\033[32m✅ Active\033[0m"
    else
      directory_status="\033[31m❌ Missing\033[0m"
    fi

    if [[ "$tmux_status" == "YES" ]]; then
      session_status="\033[32m✅ Running\033[0m"
    else
      session_status="\033[31m❌ Stopped\033[0m"
    fi

    # Print table row with proper spacing
    printf "%-11s %-19s " "$name" "$branch"
    echo -ne "${pr_color}$(printf "%-7s" "$pr_status")\033[0m "
    echo -ne "$(printf "%-18s" "$directory_status") "
    echo -e "$session_status"
  done <<< "$branches"
}
