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

CLAUDE_COMMAND="$(
  cat << 'EOF'
GH_TOKEN="$(gh auth token)" claude
EOF
)"

start_claude_in_tmux() {
  local session="$1"
  local window="$2"
  local worktree_path="$3"
  local create_new_session="$4"
  local initial_prompt="$5"

  if [[ "$create_new_session" == "true" ]]; then
    tmux new-session -ds "$session" -n "$window" -c "${worktree_path}"
  else
    tmux new-window -t "$session" -n "$window" -c "${worktree_path}"
  fi

  tmux send-keys -t "$session:$window" "$CLAUDE_COMMAND" C-m

  # If initial prompt is provided, send it after a short delay
  if [[ -n "$initial_prompt" ]]; then
    # Schedule the initial prompt to be sent after claude starts up
    (
      sleep 3 # Wait for claude to initialize
      tmux send-keys -t "$session:$window" "$initial_prompt" C-m
    ) &
  fi

  tmux switch-client -t "$session" 2> /dev/null || true
}

close_tmux_window() {
  local session="$1"
  local window="$2"

  # Check how many windows are in the current session
  local window_count
  window_count=$(tmux list-windows -t "$session" 2> /dev/null | wc -l)

  # If only one window remains, switch to previous session before killing window
  if [[ "$window_count" -eq 1 ]]; then
    debug "Only one window remains in session '$session', switching to previous session..."
    # Try to switch to the last session (previous session)
    if ! tmux switch-client -l 2> /dev/null; then
      # If no previous session, try to switch to any other session
      local other_session
      other_session=$(tmux list-sessions -F '#{session_name}' 2> /dev/null | grep -v "^${session}$" | head -n1)
      if [[ -n "$other_session" ]]; then
        tmux switch-client -t "$other_session" 2> /dev/null || true
      fi
    fi
  fi

  # If window name is empty, close current window
  if [[ -z "$window" ]]; then
    debug "Closing current tmux window..."
    tmux kill-window || return 0
    return 0
  fi

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
  debug "Current tmux session: '${current_session}'"
  [[ "$current_session" != "vibe" ]] && return 1

  # Get current branch name
  local current_branch
  current_branch=$(git symbolic-ref --short HEAD 2> /dev/null) || return 1
  debug "Current branch: '${current_branch}'"

  # Check if branch matches vibe pattern: claude/<name>
  if [[ "$current_branch" =~ ^claude/(.+)$ ]]; then
    local extracted_name="${BASH_REMATCH[1]}"
    debug "Extracted name from branch: '${extracted_name}'"
    echo "${extracted_name}"
    return 0
  fi

  debug "Current branch is not a vibe branch"
  return 1
}
