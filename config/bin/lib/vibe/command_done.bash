#!/usr/bin/env bash
# Done command functions for vibe

parse_done_command() {
  local force=false
  local name=""

  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      --force | -f)
        force=true
        shift
        ;;
      -*)
        error_usage "unknown option '$1'"
        ;;
      *)
        [[ -n "$name" ]] && error_usage "'done' requires exactly one name argument"
        name="$1"
        shift
        ;;
    esac
  done

  # If no name provided, try to get from current tmux window
  if [[ -z "$name" ]]; then
    if name=$(get_current_vibe_name); then
      debug "Detected current vibe: ${name}"
    else
      error_usage "'done' requires a name argument (or run from within a vibe tmux window)"
    fi
  fi

  echo "$name $force"
}

handle_done() {
  local branch="$1"
  local worktree_path="$2"
  local worktree_dir="$3"
  local force="$4"
  local session_name="$5"
  local project_name="$6"
  local git_root="$7"

  # Verify branch exists
  check_branch_exists "${branch}" || error_exit "Branch '${branch}' does not exist"

  # Verify branch is merged (unless forced)
  verify_branch_merged "${branch}" "${force}"

  # Change to git root directory if we're currently in the worktree
  if [[ "$PWD" == "${worktree_path}"* ]]; then
    cd "${git_root}" || error_exit "Failed to change directory"
  fi

  # Clean up resources
  remove_worktree "${worktree_path}" "${worktree_dir}"
  delete_branch "${branch}" "${force}"

  # Extract name from branch
  local name="${branch#claude/}"
  local window_name="${project_name}-${name}"
  close_tmux_window "$session_name" "${window_name}"

  echo "Done! Branch '${branch}' and worktree '${worktree_dir}' have been removed."
}
