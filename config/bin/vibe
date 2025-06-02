#!/usr/bin/env bash
#
# vibe - Claude Code wrapper with tmux session and git worktree management
#
# Requirements:
#   - tmux
#   - git
#   - claude (Claude Code CLI)
#
# Usage:
#   vibe start [<name>]
#   vibe start -m|--message <description>
#   vibe done [<name>] [--force|-f]
#   vibe list
#
set -euo pipefail

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/lib/vibe"

# Common utility functions
error_exit() {
  echo -e "error: $1" >&2
  exit 1
}

error_usage() {
  echo "error: $1" >&2
  usage
  exit 1
}

usage() {
  cat << EOF
Usage: $(basename "$0") [--debug] [-R|--repo <path>] <command> [<args>]

Global Options:
  --debug           Enable debug output
  -R, --repo <name> Specify repository by name (e.g., dotfiles, fohte/dotfiles)

Commands:
  start [<name>]
    Start a new Claude Code session with worktree
    If <name> is omitted, enters interactive mode to generate a name

  start -m|--message <description>
    Start a new session with an auto-generated name based on the description

  done [<name>] [--force|-f]
    Remove branch and worktree (only if merged)
    If <name> is omitted, uses current window name in vibe session
    Use --force or -f to skip merge check

  list
    List all active vibe sessions with their status

vibe is a wrapper for Claude Code that:
  - Creates/enters a tmux session 'vibe'
  - Creates a git branch 'claude/<name>' from origin/master
  - Creates a worktree at '.worktrees/<name>'
  - Starts Claude Code in a new tmux window
EOF
}

# Source library files
# SC1091: Disable "Not following" warning for dynamic source paths
# These files are sourced at runtime using variables, making static analysis difficult
# See: https://github.com/koalaman/shellcheck/issues/2176
# shellcheck disable=SC1091
source "${LIB_DIR}/git.bash"
# shellcheck disable=SC1091
source "${LIB_DIR}/tmux.bash"
# shellcheck disable=SC1091
source "${LIB_DIR}/claude_project.bash"
# shellcheck disable=SC1091
source "${LIB_DIR}/command_start.bash"
# shellcheck disable=SC1091
source "${LIB_DIR}/command_done.bash"
# shellcheck disable=SC1091
source "${LIB_DIR}/command_list.bash"

# Debug function
debug() {
  if [[ "${VIBE_DEBUG:-}" == "1" ]]; then
    echo "DEBUG: $*" >&2
  fi
}

# Resolve repository name to path using ghq
resolve_repo_path() {
  local repo_name="$1"

  # Get matching repository paths
  local repo_paths
  repo_paths=$(ghq list -p "$repo_name" 2> /dev/null)

  if [[ -z "$repo_paths" ]]; then
    error_exit "repository '${repo_name}' not found in ghq repositories"
  fi

  # Look for exact match first (matching the last component of the path)
  local repo_path
  while IFS= read -r path; do
    if [[ "$(basename "$path")" == "$repo_name" ]]; then
      repo_path="$path"
      break
    fi
  done <<< "$repo_paths"

  # If no exact match found, use the first result
  if [[ -z "$repo_path" ]]; then
    repo_path=$(echo "$repo_paths" | head -1)
  fi

  debug "Resolved '${repo_name}' to '${repo_path}'"
  echo "$repo_path"
}

# Parse arguments to extract global options and command
VIBE_DEBUG=0
VIBE_REPO_PATH=""
command=""
command_args=()

# Parse arguments: separate global options from command and its arguments
# We iterate through all arguments to handle options in any position
all_args=("$@")
i=0
while [[ $i -lt ${#all_args[@]} ]]; do
  arg="${all_args[$i]}"
  case "$arg" in
    --debug)
      VIBE_DEBUG=1
      ((i++)) || true # move to next argument
      ;;
    -R | --repo)
      if [[ $((i + 1)) -lt ${#all_args[@]} ]]; then # check if repo name is provided after -R
        VIBE_REPO_PATH="${all_args[$((i + 1))]}"
        ((i += 2)) || true # skip both -R and its argument
      else
        error_usage "option '$arg' requires an argument"
      fi
      ;;
    start | done | list)
      # Found command
      if [[ -z "$command" ]]; then
        command="$arg"
      else
        # This is an argument to the command, not the command itself
        command_args+=("$arg")
      fi
      ((i++)) || true # move to next argument
      ;;
    *)
      # If we have a command, this is a command argument
      if [[ -n "$command" ]]; then
        command_args+=("$arg")
      fi
      ((i++)) || true # move to next argument
      ;;
  esac
done

# Main script
[[ -z "$command" ]] && error_usage "missing command"

# Main execution
# Change to specified repo directory if provided
if [[ -n "${VIBE_REPO_PATH}" ]]; then
  resolved_path=$(resolve_repo_path "${VIBE_REPO_PATH}")
  [[ ! -d "${resolved_path}" ]] && error_exit "repository path '${resolved_path}' does not exist"
  cd "${resolved_path}" || error_exit "failed to change to repository path '${resolved_path}'"
fi

# Verify prerequisites
verify_git_repo

# Get the main git directory (not worktree)
# Use git rev-parse --git-common-dir to get the shared git directory
git_common_dir="$(git rev-parse --git-common-dir)"
# Convert to absolute path if relative
if [[ "$git_common_dir" != /* ]]; then
  git_common_dir="$(cd "$(dirname "$git_common_dir")" && pwd)/$(basename "$git_common_dir")"
fi

# Extract the main repository path from the git directory
git_root="$(dirname "${git_common_dir}")"
project_name="$(basename "${git_root}")"

# Fallback to git rev-parse --show-toplevel if project_name is empty or '.'
if [[ -z "$project_name" || "$project_name" == "." ]]; then
  git_toplevel="$(git rev-parse --show-toplevel)"
  project_name="$(basename "$git_toplevel")"
fi

SESSION_NAME="vibe"

# Parse command and get name
case "$command" in
  start)
    parsed_output=$(parse_start_command "${command_args[@]}")
    name=$(echo "$parsed_output" | head -n1)
    initial_prompt=$(echo "$parsed_output" | tail -n+2)
    branch="claude/${name}"
    worktree_dir=".worktrees/${name}"
    worktree_path="${git_root}/${worktree_dir}"
    handle_start "${branch}" "${worktree_path}" "${worktree_dir}" "${SESSION_NAME}" "${project_name}" "${git_root}" "$initial_prompt"
    ;;
  done)
    parsed_output=$(parse_done_command "${command_args[@]}") || exit 1
    read -r name force from_current_window <<< "$parsed_output"
    branch="claude/${name}"
    worktree_dir=".worktrees/${name}"
    worktree_path="${git_root}/${worktree_dir}"
    handle_done "${branch}" "${worktree_path}" "${worktree_dir}" "${force}" "${SESSION_NAME}" "${git_root}" "${from_current_window}"
    ;;
  list)
    parse_list_command "${command_args[@]}"
    handle_list
    ;;
  *)
    error_usage "unknown command '$command'"
    ;;
esac
