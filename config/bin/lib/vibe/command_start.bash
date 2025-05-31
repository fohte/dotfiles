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

    echo -e "\nSuggested project name: \033[1m$suggested_name\033[0m" >&2
    echo -ne "\033[1mUse this name? (Y/n):\033[0m " >&2
    read -r confirm

    if [[ "$confirm" =~ ^[Nn]$ ]]; then
      echo -ne "\033[1mEnter your preferred name:\033[0m " >&2
      read -r suggested_name
    fi

    # Return both name and initial prompt
    echo "$suggested_name"
    echo "$message"
  elif [[ -n "$name" ]]; then
    # Direct name provided
    echo "$name"
    echo "" # No initial prompt
  else
    # Interactive mode
    echo -ne "\033[1mWhat would you like to work on:\033[0m " >&2
    read -r description

    local suggested_name
    suggested_name=$(generate_name_from_description "$description")

    echo -e "\nSuggested project name: \033[1m$suggested_name\033[0m" >&2
    echo -ne "\033[1mUse this name? (Y/n):\033[0m " >&2
    read -r confirm

    if [[ "$confirm" =~ ^[Nn]$ ]]; then
      echo -ne "\033[1mEnter your preferred name:\033[0m " >&2
      read -r suggested_name
    fi

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
  local window_name="${project_name}-${name}"

  # Setup Claude project directory symlink before starting Claude Code
  # This needs git_root from the parent scope
  setup_claude_project_symlink "${worktree_path}" "${git_root}"

  start_claude_in_tmux "$session_name" "$window_name" "${worktree_path}" "$create_new_session" "$initial_prompt"
}
