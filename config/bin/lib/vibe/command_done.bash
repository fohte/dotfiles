#!/usr/bin/env bash
# Done command functions for vibe

parse_done_command() {
  local force=false
  local name=""
  local from_current_window=false

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
      from_current_window=true
    else
      error_usage "'done' requires a name argument (or run from within a vibe tmux window)"
    fi
  fi

  echo "$name $force $from_current_window"
}

handle_done() {
  local branch="$1"
  local worktree_path="$2"
  local worktree_dir="$3"
  local force="$4"
  local session_name="$5"
  local git_root="$6"
  local from_current_window="${7:-false}"

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

  # Remove Claude project directory symlink
  remove_claude_project_symlink "${worktree_path}"

  # Extract name from branch
  local name="${branch#claude/}"

  # Check if we got the name from current window (no argument case)
  if [[ "$from_current_window" == "true" ]]; then
    # Close current window instead of trying to match by name
    debug "Closing current tmux window..."
    close_tmux_window_by_id "$session_name" ""
  else
    # Find window ID by vibe name
    debug "Looking for window with vibe name: ${name}"
    local window_id
    window_id=$(get_window_id_by_vibe_name "$session_name" "$name")
    if [[ -n "$window_id" ]]; then
      debug "Found window ID: ${window_id}"
      close_tmux_window_by_id "$session_name" "$window_id"
    else
      debug "No window found for vibe name: ${name}"
    fi
  fi

  echo "Done! Branch '${branch}' and worktree '${worktree_dir}' have been removed."
}
