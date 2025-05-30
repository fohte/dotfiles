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

  echo "Active vibe sessions:"
  echo

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

    # Get branch status (ahead/behind main)
    local branch_status=""
    if git show-ref --verify --quiet "refs/heads/${branch}"; then
      local ahead_behind
      if ahead_behind=$(git rev-list --left-right --count origin/master..."${branch}" 2> /dev/null); then
        local behind ahead
        behind=$(echo "$ahead_behind" | cut -f1)
        ahead=$(echo "$ahead_behind" | cut -f2)

        if [[ "$ahead" -gt 0 ]] && [[ "$behind" -gt 0 ]]; then
          branch_status="(ahead $ahead, behind $behind)"
        elif [[ "$ahead" -gt 0 ]]; then
          branch_status="(ahead $ahead)"
        elif [[ "$behind" -gt 0 ]]; then
          branch_status="(behind $behind)"
        else
          branch_status="(up to date)"
        fi
      fi
    fi

    echo "  $name"
    echo "    Branch:    $branch $branch_status"
    echo "    Worktree:  $worktree_status $worktree_dir"
    echo "    Tmux:      $tmux_status $window_name"
    echo
  done <<< "$branches"
}
