#!/usr/bin/env bash
# Tmux-related functions for vibe

tmux_session_exists() {
  local session="$1"
  tmux has-session -t "$session" 2> /dev/null
}

tmux_window_exists() {
  local session="$1"
  local window="$2"
  tmux list-windows -t "$session" -F "#{window_name}" 2> /dev/null | grep -q "^${window}$"
}

start_claude_in_tmux() {
  local session="$1"
  local window="$2"
  local worktree_path="$3"
  local create_new_session="$4"

  if [[ "$create_new_session" == "true" ]]; then
    tmux new-session -ds "$session" -n "$window" -c "${worktree_path}"
  else
    tmux new-window -t "$session" -n "$window" -c "${worktree_path}"
  fi

  tmux send-keys -t "$session:$window" "claude" C-m
  tmux switch-client -t "$session" 2> /dev/null || true
}

close_tmux_window() {
  local session="$1"
  local window="$2"

  tmux_window_exists "$session" "$window" || return 0

  debug "Closing tmux window '${window}'..."
  tmux kill-window -t "$session:${window}"
}

get_current_vibe_name() {
  # Check if we're in tmux
  [[ -z "${TMUX:-}" ]] && return 1

  # Check if current session is 'vibe'
  local current_session
  current_session=$(tmux display-message -p '#S' 2> /dev/null)
  [[ "$current_session" != "vibe" ]] && return 1

  # Get current window name
  local window_name
  window_name=$(tmux display-message -p '#W' 2> /dev/null)

  # Get the main git directory (not worktree)
  local git_common_dir
  git_common_dir=$(git rev-parse --git-common-dir 2> /dev/null) || return 1

  # Get the parent directory name (project name)
  local project_name
  project_name=$(basename "$(dirname "${git_common_dir}")")

  # Check if window name matches expected pattern: <project>-<name>
  if [[ "$window_name" =~ ^${project_name}-(.+)$ ]]; then
    echo "${BASH_REMATCH[1]}"
    return 0
  fi

  return 1
}
