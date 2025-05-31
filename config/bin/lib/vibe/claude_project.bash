#!/usr/bin/env bash
# Claude Code project directory management functions

# Debug function (if not already defined)
if ! declare -f debug > /dev/null; then
  debug() {
    if [[ "${VIBE_DEBUG:-}" == "1" ]]; then
      echo "DEBUG: $*" >&2
    fi
  }
fi

# Setup Claude Code project directory symlink
# This ensures all worktrees share the same Claude project directory
setup_claude_project_symlink() {
  local worktree_path="$1"
  local git_root="$2"

  # Convert paths to Claude Code's directory naming format
  # Claude Code replaces all non-alphanumeric characters with dashes
  # Using printf to avoid trailing newline that would become a dash
  local worktree_project_name
  worktree_project_name=$(printf '%s' "$worktree_path" | tr -c 'a-zA-Z0-9' '-')

  local root_project_name
  root_project_name=$(printf '%s' "$git_root" | tr -c 'a-zA-Z0-9' '-')

  local claude_projects_dir="${HOME}/.claude/projects"
  local worktree_project_dir="${claude_projects_dir}/${worktree_project_name}"
  local root_project_dir="${claude_projects_dir}/${root_project_name}"

  debug "Claude project directories:"
  debug "  Worktree: ${worktree_project_dir}"
  debug "  Root: ${root_project_dir}"

  # If worktree project directory already exists and is not a symlink, skip
  if [[ -e "${worktree_project_dir}" && ! -L "${worktree_project_dir}" ]]; then
    debug "Worktree project directory already exists and is not a symlink, skipping"
    return 0
  fi

  # Create root project directory if it doesn't exist
  if [[ ! -d "${root_project_dir}" ]]; then
    debug "Creating root project directory: ${root_project_dir}"
    mkdir -p "${root_project_dir}"
  fi

  # Remove existing symlink if it exists
  if [[ -L "${worktree_project_dir}" ]]; then
    debug "Removing existing symlink: ${worktree_project_dir}"
    rm "${worktree_project_dir}"
  fi

  # Create symlink from worktree project to root project
  debug "Creating symlink: ${worktree_project_dir} -> ${root_project_dir}"
  ln -s "${root_project_dir}" "${worktree_project_dir}"

  debug "Linked Claude project: worktree → root repository"
}

# Remove Claude Code project directory symlink
remove_claude_project_symlink() {
  local worktree_path="$1"

  # Convert path to Claude Code's directory naming format
  local worktree_project_name
  worktree_project_name=$(printf '%s' "$worktree_path" | tr -c 'a-zA-Z0-9' '-')

  local claude_projects_dir="${HOME}/.claude/projects"
  local worktree_project_dir="${claude_projects_dir}/${worktree_project_name}"

  # Remove symlink if it exists
  if [[ -L "${worktree_project_dir}" ]]; then
    debug "Removing Claude project symlink: ${worktree_project_dir}"
    rm "${worktree_project_dir}"
    debug "Removed Claude project symlink"
  else
    debug "No symlink found at: ${worktree_project_dir}"
  fi
}
