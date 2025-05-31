#!/usr/bin/env bash
# List command functions for vibe

parse_list_command() {
  # No arguments expected for list command
  if [[ "$#" -ne 0 ]]; then
    error_usage "'list' takes no arguments"
  fi
}

handle_list() {
  # Collect all data first, then format with column
  local table_data=""
  table_data="REPOSITORY\tNAME\tSTATUS\tPR_URL"
  local found_any_sessions=false

  # Get all repositories using ghq
  local repos
  repos=$(ghq list --full-path 2> /dev/null) || {
    echo "Error: ghq not found or no repositories available."
    return 1
  }

  # Check each repository for vibe branches
  while IFS= read -r repo_path; do
    [[ -z "$repo_path" ]] && continue
    [[ ! -d "$repo_path" ]] && continue

    # Change to repository directory
    local original_dir="$PWD"
    cd "$repo_path" || continue

    # Get all vibe branches (claude/*) in this repository
    local branches
    branches=$(git branch --list 'claude/*' --format='%(refname:short)' 2> /dev/null)

    # Skip if no vibe branches found
    if [[ -z "$branches" ]]; then
      cd "$original_dir" || return 1
      continue
    fi

    # Filter out empty results
    branches=$(echo "$branches" | grep -v '^$' || true)

    if [[ -z "$branches" ]]; then
      cd "$original_dir" || return 1
      continue
    fi

    found_any_sessions=true

    # Get repository name from git remote
    local repo_name
    repo_name=$(git remote get-url origin 2> /dev/null | sed -E 's|.*/([^/]+/[^/]+)(\.git)?$|\1|' | sed 's/\.git$//')

    # If no remote, use the directory name as fallback
    if [[ -z "$repo_name" ]]; then
      repo_name=$(basename "$repo_path")
    fi

    # List each vibe session with status
    while IFS= read -r branch; do
      [[ -z "$branch" ]] && continue

      local name="${branch#claude/}"

      # Check session status (done or in-progress) and get PR URL
      local session_status_value pr_url
      pr_url=$(gh pr list --state all --head "${branch}" --json url --jq '.[0].url' 2> /dev/null || echo "")

      if check_pr_merged "${branch}"; then
        session_status_value="done"
      elif is_branch_merged "${branch}"; then
        session_status_value="done"
      else
        session_status_value="in-progress"
      fi

      # Show "-" if no PR URL found
      if [[ -z "$pr_url" ]]; then
        pr_url="-"
      fi

      # Add row to table data
      table_data="$table_data\n$repo_name\t$name\t$session_status_value\t$pr_url"
    done <<< "$branches"

    # Return to original directory
    cd "$original_dir" || return 1
  done <<< "$repos"

  # Check if any sessions were found
  if [[ "$found_any_sessions" == false ]]; then
    echo "No active vibe sessions found."
    return 0
  fi

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
