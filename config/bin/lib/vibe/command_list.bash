#!/usr/bin/env bash
# List command functions for vibe

parse_list_command() {
  # No arguments expected for list command
  if [[ "$#" -ne 0 ]]; then
    error_usage "'list' takes no arguments"
  fi
}

get_session_status() {
  local branch="$1"

  if check_pr_merged "${branch}"; then
    echo "done"
  elif is_branch_merged "${branch}"; then
    echo "done"
  else
    echo "in-progress"
  fi
}

process_vibe_sessions() {
  local repo_path="$1"
  local repo_name="$2"
  local branches="$3"
  local table_data_var="$4"

  while IFS= read -r branch; do
    [[ -z "$branch" ]] && continue

    local name="${branch#claude/}"

    # Check if worktree exists (only show managed sessions)
    local worktree_dir=".worktrees/${name}"
    if [[ ! -d "$worktree_dir" ]]; then
      continue
    fi

    # Get PR URL and session status
    local pr_url session_status_value
    pr_url=$(get_pr_url "${branch}")
    session_status_value=$(get_session_status "${branch}")

    # Add row to table data
    printf -v "$table_data_var" "%s\n%s\t%s\t%s\t%s" "${!table_data_var}" "$repo_name" "$name" "$session_status_value" "$pr_url"
  done <<< "$branches"
}

process_repository() {
  local repo_path="$1"
  local original_dir="$2"
  local table_data_var="$3"
  local found_sessions_var="$4"

  [[ -z "$repo_path" ]] && return 0
  [[ ! -d "$repo_path" ]] && return 0

  # Change to repository directory
  cd "$repo_path" || return 0

  # Get all vibe branches (claude/*) in this repository
  local branches
  branches=$(list_vibe_branches)

  # Skip if no vibe branches found
  if [[ -z "$branches" ]]; then
    cd "$original_dir" || return 1
    return 0
  fi

  # Filter out empty results
  branches=$(echo "$branches" | grep -v '^$' || true)

  if [[ -z "$branches" ]]; then
    cd "$original_dir" || return 1
    return 0
  fi

  printf -v "$found_sessions_var" "true"

  # Get repository name
  local repo_name
  repo_name=$(get_repo_name_from_remote "$repo_path")

  # Process each vibe session
  process_vibe_sessions "$repo_path" "$repo_name" "$branches" "$table_data_var"

  # Return to original directory
  cd "$original_dir" || return 1
}

format_and_display_table() {
  local table_data="$1"

  # Output formatted table with colors applied after column alignment
  echo -e "$table_data" | column -t | while IFS= read -r line; do
    if [[ "$line" == "REPOSITORY"* ]]; then
      # Header row - make it bold
      echo -e "\033[1m$line\033[0m"
    else
      # Data row - apply colors to specific fields
      echo "$line" | sed \
        -e 's/done/\x1b[32mdone\x1b[0m/' \
        -e 's/in-progress/\x1b[33min-progress\x1b[0m/'
    fi
  done
}

handle_list() {
  local table_data="REPOSITORY\tNAME\tSTATUS\tPR_URL"
  local found_any_sessions="false"

  # Get all repositories using ghq
  local repos
  repos=$(ghq list --full-path 2> /dev/null) || {
    echo "Error: ghq not found or no repositories available."
    return 1
  }

  # Process each repository
  local original_dir="$PWD"
  while IFS= read -r repo_path; do
    process_repository "$repo_path" "$original_dir" table_data found_any_sessions
  done <<< "$repos"

  # Check if any sessions were found
  if [[ "$found_any_sessions" == "false" ]]; then
    echo "No active vibe sessions found."
    return 0
  fi

  # Display the formatted table
  format_and_display_table "$table_data"
}
