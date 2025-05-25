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
  pr_info=$(gh pr list --state all --head "${branch}" --json number,merged,state --limit 1 2> /dev/null)

  [[ -n "$pr_info" && "$pr_info" != "[]" ]] || return 1
  echo "$pr_info" | jq -e '.[0].merged == true' > /dev/null 2>&1
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
  check_pr_merged "${branch}" && return 0

  # Fall back to git branch --merged
  is_branch_merged "${branch}" && return 0

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
