#!/usr/bin/env bash
# Git-related functions for vibe

verify_git_repo() {
  git rev-parse --git-dir > /dev/null 2>&1 || error_exit "not in a git repository"
}

check_branch_exists() {
  local branch="$1"
  git show-ref --verify --quiet "refs/heads/${branch}"
}

is_branch_merged() {
  local branch="$1"
  git branch --merged | grep -q "^[[:space:]]*${branch}$"
}

check_pr_merged() {
  local branch="$1"
  command -v gh &> /dev/null || return 1

  local pr_info
  pr_info=$(gh pr list --state all --head "${branch}" --json number,mergedAt,state --limit 1 2> /dev/null)

  [[ -n "$pr_info" && "$pr_info" != "[]" ]] || return 1
  # Check if mergedAt is not null (meaning it was merged)
  echo "$pr_info" | jq -e '.[0].mergedAt != null' > /dev/null 2>&1
}

create_branch_from_origin() {
  local branch="$1"
  debug "Creating branch '${branch}' from origin/master..."
  git fetch origin master
  git branch "${branch}" origin/master
}

create_worktree() {
  local path="$1"
  local branch="$2"
  debug "Creating worktree at '${path}'..."
  git worktree add "${path}" "${branch}"
}

verify_branch_merged() {
  local branch="$1"
  local force="$2"

  [[ "$force" == "true" ]] && debug "Force deletion requested, skipping merge check..." && return 0

  # Try GitHub PR first (handles squash merge)
  debug "Checking if PR is merged for branch '${branch}'"
  if check_pr_merged "${branch}"; then
    debug "PR is merged"
    return 0
  else
    debug "PR not found or not merged, falling back to git branch --merged"
  fi

  # Fall back to git branch --merged
  if is_branch_merged "${branch}"; then
    debug "Branch is merged according to git"
    return 0
  else
    debug "Branch is not merged according to git"
  fi

  # Extract name from branch for error message
  local branch_name="${branch#claude/}"
  error_exit "branch '${branch}' has not been merged yet\nPlease merge the branch first or use 'vibe done ${branch_name} --force' to force delete"
}

remove_worktree() {
  local worktree_path="$1"
  local worktree_dir="$2"

  [[ ! -d "${worktree_path}" ]] && return 0

  debug "Removing worktree at '${worktree_dir}'..."
  git worktree remove "${worktree_path}"
}

delete_branch() {
  local branch="$1"
  local force="$2"

  debug "Deleting branch '${branch}'..."
  if [[ "$force" == "true" ]]; then
    git branch -D "${branch}"
  else
    git branch -d "${branch}"
  fi
}

get_pr_url() {
  local branch="$1"
  command -v gh &> /dev/null || {
    echo "-"
    return 0
  }

  local pr_url
  pr_url=$(gh pr list --state all --head "${branch}" --json url --jq '.[0].url' 2> /dev/null || echo "")

  # Show "-" if no PR URL found
  if [[ -z "$pr_url" ]]; then
    pr_url="-"
  fi

  echo "$pr_url"
}

get_repo_name_from_remote() {
  local repo_path="$1"
  local repo_name

  # Try to get from git remote first
  repo_name=$(git remote get-url origin 2> /dev/null | sed -E 's|.*/([^/]+/[^/]+)(\.git)?$|\1|' | sed 's/\.git$//')

  # If no remote, use the directory name as fallback
  if [[ -z "$repo_name" ]]; then
    repo_name=$(basename "$repo_path")
  fi

  echo "$repo_name"
}

list_vibe_branches() {
  git branch --list 'claude/*' --format='%(refname:short)' 2> /dev/null
}
