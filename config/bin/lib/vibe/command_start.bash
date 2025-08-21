#!/usr/bin/env bash
# Start command functions for vibe

show_claude_spinner() {
  local message="$1"
  local spinner_chars="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
  local i=0

  while true; do
    printf "\r🤖 %s %s" "$message" "${spinner_chars:$i:1}" >&2
    i=$(((i + 1) % ${#spinner_chars}))
    sleep 0.1
  done
}

generate_name_from_description() {
  local description="$1"

  # Use Claude to generate a project name based on the description
  local claude_prompt="Task: Convert the following user task description to a git branch name (2-4 words, lowercase, hyphens).

<user-task-description>
${description}
</user-task-description>

IMPORTANT: Output ONLY the branch name. Do not analyze, explain, or investigate the task. Just generate the name."

  # Start spinner in background
  show_claude_spinner "Asking Claude for project name suggestions..." &
  local spinner_pid=$!

  # Function to clean up spinner
  cleanup_spinner() {
    kill $spinner_pid 2> /dev/null || true
    printf "\r🤖 Asking Claude for project name suggestions... ✨ Done!    \n" >&2
  }

  # Ensure spinner is killed on exit
  trap cleanup_spinner EXIT

  local suggested_name
  suggested_name=$(echo "$claude_prompt" | claude --model "${VIBE_BRANCH_MODEL:-haiku}" --print 2> /dev/null | head -n1 | tr -d '\r')

  # Stop spinner and clear line
  cleanup_spinner
  trap - EXIT # Remove the trap

  # Validate the generated name
  if [[ -z "$suggested_name" ]]; then
    error_exit "Failed to generate project name suggestion"
  fi

  # Ensure the name is valid for a git branch
  if ! echo "$suggested_name" | grep -qE '^[a-z0-9][a-z0-9-]*$'; then
    error_exit "Generated name '$suggested_name' is not valid for a git branch"
  fi

  echo "$suggested_name"
}

get_message_from_editor() {
  # Create a temporary file for editor input
  local temp_file
  temp_file=$(mktemp)

  # Add instructions to the temporary file
  cat > "$temp_file" << 'EOF'

# Please enter your task description above this line.
# Lines starting with '#' will be ignored.
# The description will be used to generate a project name and
# passed to Claude as the initial prompt.
#
# Examples:
#   Implement user authentication with OAuth2
#   Fix memory leak in the parser module
#   Add dark mode support to the UI
EOF

  # Determine editor to use
  local editor="${EDITOR:-${VISUAL:-nano}}"

  # Open editor
  "$editor" "$temp_file" >&2

  # Read the content and filter out comments and empty lines
  local message
  message=$(grep -v '^#' "$temp_file" | sed '/^\s*$/d' | sed 's/[[:space:]]*$//')

  # Clean up
  rm -f "$temp_file"

  # Return the message
  echo "$message"
}

parse_start_command() {
  local message=""
  local name=""
  local initial_prompt=""

  # Parse options
  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      -m | --message)
        [[ "$#" -lt 2 ]] && error_usage "option '$1' requires an argument"
        message="$2"
        shift 2
        ;;
      -*)
        error_usage "unknown option '$1'"
        ;;
      *)
        [[ -n "$name" ]] && error_usage "'start' accepts only one name argument"
        name="$1"
        shift
        ;;
    esac
  done

  # Handle different cases
  if [[ -n "$message" ]]; then
    # Generate name from message
    local suggested_name
    suggested_name=$(generate_name_from_description "$message")

    echo -e "\nGenerated project name: \033[1m$suggested_name\033[0m" >&2

    # Display the initial prompt
    echo -e "\n─ Prompt ─────────────────────────────────" >&2
    echo -e "\033[2m$message\033[0m" >&2
    echo -e "──────────────────────────────────────────" >&2
    echo "" >&2

    # Return both name and initial prompt
    echo "$suggested_name"
    echo "$message"
  elif [[ -n "$name" ]]; then
    # Direct name provided
    echo "$name"
    echo "" # No initial prompt
  else
    # Editor mode: launch editor for message input
    echo -e "\033[1mLaunching editor for task description...\033[0m" >&2
    local description
    description=$(get_message_from_editor)

    # Check if user provided a description
    if [[ -z "$description" ]]; then
      error_exit "No task description provided"
    fi

    local suggested_name
    suggested_name=$(generate_name_from_description "$description")

    echo -e "\nGenerated project name: \033[1m$suggested_name\033[0m" >&2

    # Display the initial prompt
    echo -e "\n─ Prompt ─────────────────────────────────" >&2
    echo -e "\033[2m$description\033[0m" >&2
    echo -e "──────────────────────────────────────────" >&2
    echo "" >&2

    # Return both name and initial prompt
    echo "$suggested_name"
    echo "$description"
  fi
}

handle_start() {
  local branch="$1"
  local worktree_path="$2"
  local worktree_dir="$3"
  local session_name="$4"
  local project_name="$5"
  local git_root="$6"
  local initial_prompt="$7"

  # Check prerequisites
  check_branch_exists "${branch}" && error_exit "Branch '${branch}' already exists"
  [[ -d "${worktree_path}" ]] && error_exit "Worktree '${worktree_dir}' already exists"

  # Create branch and worktree
  create_branch_from_origin "${branch}"
  create_worktree "${worktree_path}" "${branch}"

  # Setup tmux
  local create_new_session=false
  tmux_session_exists "$session_name" || create_new_session=true

  # Extract name from branch
  local name="${branch#claude/}"
  local window_name="${project_name}/${name}"

  # Setup Claude project directory symlink before starting Claude Code
  # This needs git_root from the parent scope
  setup_claude_project_symlink "${worktree_path}" "${git_root}"

  local window_id
  window_id=$(start_claude_in_tmux "$session_name" "$window_name" "${worktree_path}" "$create_new_session" "$initial_prompt")
  debug "Created tmux window with ID: ${window_id}"
}
