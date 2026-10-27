#!/bin/bash
set -u

LEGACY_BRANCH_CHECK=30
NO_CHECKOUT_TARGETS=10
DENIED=20
TARGETS=()
REALPATH_BIN=$(command -v grealpath || command -v realpath) || exit "$DENIED"

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
  local captured status result metadata_status

  captured=$(
    (
      unset GIT_DIR GIT_WORK_TREE GIT_COMMON_DIR GIT_CEILING_DIRECTORIES
      unset GIT_DISCOVERY_ACROSS_FILESYSTEM GIT_PREFIX
      git -C "$directory" rev-parse --show-toplevel 2> /dev/null
    )
    status=$?
    printf '\n__GIT_EXIT__%s' "$status"
  ) || return 2
  status=${captured##*$'\n__GIT_EXIT__'}
  result=${captured%$'\n__GIT_EXIT__'*}
  result=${result%$'\n'}

  if [[ $status != 0 ]]; then
    has_git_metadata_ancestor "$directory"
    metadata_status=$?
    case "$metadata_status" in
      1)
        if (
          unset GIT_DIR GIT_WORK_TREE GIT_COMMON_DIR GIT_CEILING_DIRECTORIES
          unset GIT_DISCOVERY_ACROSS_FILESYSTEM GIT_PREFIX
          git -C "$directory" rev-parse --is-bare-repository > /dev/null 2>&1
        ); then
          return 2
        fi
        return 1
        ;;
      *) return 2 ;;
    esac
  fi

  [[ $result == /* && $result != *$'\n'* && $result != *$'\r'* ]] || return 2
  normalize_path -e "$result" || return 2
}

has_git_metadata_ancestor() {
  local path=$1
  local parent

  while :; do
    [[ -e $path/.git || -L $path/.git ]] && return 0
    parent=$(dirname -- "$path") || return 2
    [[ $parent != "$path" ]] || return 1
    path=$parent
  done
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

checkout_targets=0
for raw_target in "${TARGETS[@]}"; do
  if [[ $raw_target == /* ]]; then
    target=$raw_target
  else
    target=$cwd/$raw_target
  fi
  target=$(normalize_path -m "$target") || deny

  target_directory_input=$target
  if [[ ! -d $target_directory_input ]]; then
    target_directory_input=$(dirname -- "$target") || deny
  fi
  target_directory=$(existing_directory "$target_directory_input") || deny
  if target_root=$(git_root "$target_directory"); then
    [[ $target_root == "$session_root" ]] || deny
    checkout_targets=$((checkout_targets + 1))
  else
    git_status=$?
    [[ $git_status == 1 ]] || deny
  fi
done

if [[ $checkout_targets == 0 ]]; then
  exit "$NO_CHECKOUT_TARGETS"
fi
exit 0
