#!/usr/bin/env bash
# Start command functions for vibe

generate_name_from_description() {
  local description="$1"

  # Use Claude to generate a project name based on the description
  local claude_prompt="Generate a git branch name for this task: \"${description}\". Rules: lowercase only, use hyphens not spaces, 2-4 words max. Output ONLY the branch name on a single line, no explanation."

  local suggested_name
  suggested_name=$(echo "$claude_prompt" | claude --print 2> /dev/null | head -n1 | tr -d '\r')

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

parse_start_command() {
  local message=""
  local name=""

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

    echo "Suggested project name: $suggested_name" >&2
    echo -n "Use this name? (Y/n): " >&2
    read -r confirm

    if [[ "$confirm" =~ ^[Nn]$ ]]; then
      echo -n "Enter your preferred name: " >&2
      read -r suggested_name
    fi

    echo "$suggested_name"
  elif [[ -n "$name" ]]; then
    # Direct name provided
    echo "$name"
  else
    # Interactive mode
    echo "What would you like to work on?" >&2
    read -r description

    local suggested_name
    suggested_name=$(generate_name_from_description "$description")

    echo "Suggested project name: $suggested_name" >&2
    echo -n "Use this name? (Y/n): " >&2
    read -r confirm

    if [[ "$confirm" =~ ^[Nn]$ ]]; then
      echo -n "Enter your preferred name: " >&2
      read -r suggested_name
    fi

    echo "$suggested_name"
  fi
}

handle_start() {
  local branch="$1"
  local worktree_path="$2"
  local worktree_dir="$3"
  local session_name="$4"
  local project_name="$5"

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
  local window_name="${project_name}-${name}"
  start_claude_in_tmux "$session_name" "$window_name" "${worktree_path}" "$create_new_session"
}
