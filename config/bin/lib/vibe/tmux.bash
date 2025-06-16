#!/usr/bin/env bash
# Tmux-related functions for vibe

# Get window ID for a given vibe name
get_window_id_by_vibe_name() {
  local session="$1"
  local vibe_name="$2"

  # List all windows and find the one matching our vibe name pattern
  while IFS=' ' read -r window_id window_name; do
    # Check if window name ends with the vibe name
    if [[ "$window_name" =~ /${vibe_name}$ ]]; then
      echo "$window_id"
      return 0
    fi
  done < <(tmux list-windows -t "$session" -F "#{window_id} #{window_name}" 2> /dev/null)

  return 1
}

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
  local initial_prompt="$5"

  local window_id
  if [[ "$create_new_session" == "true" ]]; then
    # Create new session and capture window ID
    window_id=$(tmux new-session -ds "$session" -n "$window" -c "${worktree_path}" -P -F "#{window_id}")
  else
    # Create new window and capture window ID
    window_id=$(tmux new-window -a -t "$session" -n "$window" -c "${worktree_path}" -P -F "#{window_id}")
  fi

  # Build the claude command with or without initial prompt
  local claude_command="GH_TOKEN=\"\$(gh auth token)\" claude"
  if [[ -n "$initial_prompt" ]]; then
    # Write prompt to temporary file and use command substitution
    local temp_file
    temp_file=$(mktemp)
    echo "$initial_prompt" > "$temp_file"
    claude_command="$claude_command \"\$(cat $temp_file)\""
  fi

  tmux send-keys -t "$window_id" "$claude_command" C-m

  tmux switch-client -t "$window_id" 2> /dev/null || true

  # Return the window ID for later use
  echo "$window_id"
}

close_tmux_window_by_id() {
  local session="$1"
  local window_id="$2"

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

  # If window ID is empty, close current window
  if [[ -z "$window_id" ]]; then
    debug "Closing current tmux window..."
    tmux kill-window || return 0
    return 0
  fi

  # Check if window exists
  if ! tmux list-windows -t "$session" -F "#{window_id}" 2> /dev/null | grep -q "^${window_id}$"; then
    return 0
  fi

  debug "Closing tmux window ID '${window_id}'..."
  tmux kill-window -t "$window_id"
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
