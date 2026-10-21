#!/bin/bash
set -u

LEGACY_BRANCH_CHECK=30
TEMP_ONLY=10
DENIED=20
TARGETS=()
TEMP_ROOTS=()
REALPATH_BIN=$(command -v grealpath || command -v realpath) || exit "$DENIED"
STAT_BIN=$(command -v gstat || command -v stat) || exit "$DENIED"

input=$(cat) || exit "$DENIED"
jq -e . <<< "$input" > /dev/null 2>&1 || exit "$DENIED"

tool_name=$(jq -r '.tool_name // empty' <<< "$input")
case "$tool_name" in
  apply_patch | Edit | Write | MultiEdit) ;;
  *) exit "$LEGACY_BRANCH_CHECK" ;;
esac

if ! jq -e '
  .cwd as $cwd
  | ($cwd | type == "string" and startswith("/") and (contains("\n") | not) and (contains("\r") | not) and (contains("\u0000") | not))
' <<< "$input" > /dev/null; then
  exit "$DENIED"
fi

cwd=$(jq -r '.cwd' <<< "$input") || exit "$DENIED"

deny() {
  exit "$DENIED"
}

normalize_path() {
  local mode=$1
  local path=$2
  local captured status result

  captured=$(
    "$REALPATH_BIN" "$mode" -- "$path" 2> /dev/null
    status=$?
    printf '\n__REALPATH_EXIT__%s' "$status"
  ) || return 1
  status=${captured##*$'\n__REALPATH_EXIT__'}
  result=${captured%$'\n__REALPATH_EXIT__'*}
  result=${result%$'\n'}
  [[ $status == 0 && $result == /* && $result != *$'\n'* && $result != *$'\r'* ]] || return 1
  printf '%s' "$result"
}

git_root() {
  local directory=$1
  local captured status result

  captured=$(
    (
      unset GIT_DIR GIT_WORK_TREE GIT_COMMON_DIR GIT_CEILING_DIRECTORIES
      unset GIT_DISCOVERY_ACROSS_FILESYSTEM GIT_PREFIX
      LC_ALL=C git -C "$directory" rev-parse --show-toplevel 2>&1
    )
    status=$?
    printf '\n__GIT_EXIT__%s' "$status"
  ) || return 2
  status=${captured##*$'\n__GIT_EXIT__'}
  result=${captured%$'\n__GIT_EXIT__'*}
  result=${result%$'\n'}

  if [[ $status != 0 ]]; then
    case "$result" in
      *'not a git repository'*) return 1 ;;
      *) return 2 ;;
    esac
  fi

  [[ $result == /* && $result != *$'\n'* && $result != *$'\r'* ]] || return 2
  normalize_path -e "$result" || return 2
}

path_within() {
  local path=$1
  local root=$2
  [[ $path == "$root" || $path == "$root"/* ]]
}

existing_directory() {
  local path=$1
  local parent

  while [[ ! -d $path ]]; do
    parent=$(dirname -- "$path") || return 1
    [[ $parent != "$path" ]] || return 1
    path=$parent
  done
  printf '%s' "$path"
}

private_session_temp_root() {
  local session_id=$1
  local directory=$2
  local mode mode_value

  [[ $session_id =~ ^[A-Za-z0-9_-]{1,128}$ ]] || return 1
  [[ -d $directory && ! -L $directory && -O $directory ]] || return 1
  mode=$("$STAT_BIN" -c '%a' "$directory" 2> /dev/null) || return 1
  [[ $mode =~ ^[0-7]{3,4}$ ]] || return 1
  mode_value=$((8#$mode))
  (((mode_value & 0077) == 0 && (mode_value & 0700) == 0700)) || return 1
  normalize_path -e "$directory"
}

add_target() {
  local target=$1
  [[ -n $target && $target != *$'\n'* && $target != *$'\r'* ]] || return 1
  TARGETS+=("$target")
}

parse_codex_targets() {
  local command first_line line target
  local started=0 ended=0 update_can_move=0

  if ! jq -e '
    .tool_input as $tool_input
    | ($tool_input | type == "object")
      and ($tool_input.command | type == "string" and length > 0 and (contains("\u0000") | not))
  ' <<< "$input" > /dev/null; then
    return 1
  fi
  command=$(jq -r '.tool_input.command' <<< "$input") || return 1
  [[ $command != *$'\r'* ]] || return 1
  first_line=${command%%$'\n'*}
  [[ $first_line == '*** Begin Patch' ]] || return 1

  while IFS= read -r line || [[ -n $line ]]; do
    if [[ $started == 0 ]]; then
      [[ $line == '*** Begin Patch' ]] || return 1
      started=1
      continue
    fi
    if [[ $ended == 1 ]]; then
      [[ -z $line ]] || return 1
      continue
    fi

    case "$line" in
      '*** End Patch')
        ended=1
        update_can_move=0
        ;;
      '*** Add File: '*)
        target=${line#'*** Add File: '}
        add_target "$target" || return 1
        update_can_move=0
        ;;
      '*** Delete File: '*)
        target=${line#'*** Delete File: '}
        add_target "$target" || return 1
        update_can_move=0
        ;;
      '*** Update File: '*)
        target=${line#'*** Update File: '}
        add_target "$target" || return 1
        update_can_move=1
        ;;
      '*** Move to: '*)
        [[ $update_can_move == 1 ]] || return 1
        target=${line#'*** Move to: '}
        add_target "$target" || return 1
        update_can_move=0
        ;;
      '*** End of File') ;;
      '***'*) return 1 ;;
    esac
  done <<< "$command"

  [[ $started == 1 && $ended == 1 && ${#TARGETS[@]} -gt 0 ]]
}

parse_claude_targets() {
  local file_path

  if [[ $tool_name == MultiEdit ]]; then
    if ! jq -e '
      .tool_input as $i
      | ($i | type == "object")
        and ((($i | has("file_path")) | not) or ($i.file_path | type == "string" and length > 0 and (contains("\n") | not) and (contains("\r") | not) and (contains("\u0000") | not)))
        and ((($i | has("edits")) | not) or ($i.edits | type == "array" and all(.[]; type == "object" and ((has("file_path") | not) or (.file_path | type == "string" and length > 0 and (contains("\n") | not) and (contains("\r") | not) and (contains("\u0000") | not))))))
        and (if ($i | has("file_path")) then true else ($i.edits | type == "array" and length > 0 and all(.[]; has("file_path"))) end)
    ' <<< "$input" > /dev/null; then
      return 1
    fi

    file_path=$(jq -r '.tool_input.file_path // empty' <<< "$input") || return 1
    if [[ -n $file_path ]]; then
      add_target "$file_path" || return 1
    fi
    while IFS= read -r file_path; do
      [[ -n $file_path ]] || continue
      add_target "$file_path" || return 1
    done < <(jq -r '.tool_input.edits[]?.file_path? // empty' <<< "$input")
    [[ ${#TARGETS[@]} -gt 0 ]]
    return
  fi

  if ! jq -e '
    .tool_input as $i
    | ($i | type == "object")
      and ($i.file_path | type == "string" and length > 0 and (contains("\n") | not) and (contains("\r") | not) and (contains("\u0000") | not))
  ' <<< "$input" > /dev/null; then
    return 1
  fi
  file_path=$(jq -r '.tool_input.file_path' <<< "$input") || return 1
  add_target "$file_path"
}

case "$tool_name" in
  apply_patch)
    parse_codex_targets || deny
    ;;
  Edit | Write | MultiEdit)
    parse_claude_targets || deny
    ;;
esac

if ! cwd=$(normalize_path -e "$cwd") || [[ ! -d $cwd ]]; then
  deny
fi

if session_root=$(git_root "$cwd"); then
  :
else
  git_status=$?
  if [[ $git_status == 1 ]]; then
    exit "$LEGACY_BRANCH_CHECK"
  fi
  deny
fi

session_id=$(jq -r '.session_id // empty' <<< "$input")
if [[ -n $session_id && $session_id =~ ^[A-Za-z0-9_-]{1,128}$ ]]; then
  if temp_root=$(private_session_temp_root "$session_id" "/tmp/agent-$session_id"); then
    TEMP_ROOTS+=("$temp_root")
  fi
fi

if [[ $tool_name == apply_patch && -n ${CODEX_THREAD_ID:-} && ${CODEX_THREAD_ID:-} != "$session_id" && $CODEX_THREAD_ID =~ ^[A-Za-z0-9_-]{1,128}$ ]]; then
  if temp_root=$(private_session_temp_root "$CODEX_THREAD_ID" "/tmp/agent-$CODEX_THREAD_ID"); then
    TEMP_ROOTS+=("$temp_root")
  fi
fi

checkout_targets=0
temp_targets=0
for raw_target in "${TARGETS[@]}"; do
  if [[ $raw_target == /* ]]; then
    target=$raw_target
  else
    target=$cwd/$raw_target
  fi
  target=$(normalize_path -m "$target") || deny

  is_temp_target=0
  for temp_root in "${TEMP_ROOTS[@]}"; do
    if path_within "$target" "$temp_root"; then
      is_temp_target=1
      break
    fi
  done
  if [[ $is_temp_target == 1 ]]; then
    temp_targets=$((temp_targets + 1))
    continue
  fi

  path_within "$target" "$session_root" || deny
  target_directory_input=$target
  if [[ ! -d $target_directory_input ]]; then
    target_directory_input=$(dirname -- "$target") || deny
  fi
  target_directory=$(existing_directory "$target_directory_input") || deny
  target_root=$(git_root "$target_directory") || deny
  [[ $target_root == "$session_root" ]] || deny
  checkout_targets=$((checkout_targets + 1))
done

if [[ $checkout_targets == 0 && $temp_targets -eq ${#TARGETS[@]} ]]; then
  exit "$TEMP_ONLY"
fi
exit 0
