#!/bin/bash

# shellcheck source=with-mkdir-lock.bash disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/with-mkdir-lock.bash"

register_project_trust() {
  local project_path="$1"
  local overlay org
  local home_path="${HOME:-}"
  local claude_json="$home_path/.claude.json"
  local codex_config="$home_path/.codex/config.toml"
  local is_own_repo=false
  local -a own_orgs=(fohte)

  if overlay="$(dot role overlay config/github-orgs)"; then
    while IFS= read -r org || [[ -n "$org" ]]; do
      [[ -n "$org" ]] && own_orgs+=("$org")
    done < "$overlay"
  fi

  for org in "${own_orgs[@]}"; do
    [[ "$project_path" == "$home_path/ghq/github.com/$org/"* ]] && is_own_repo=true
  done

  [[ "$is_own_repo" == true ]] || return 0

  if [[ -f "$claude_json" ]] &&
    ! jq -e --arg path "$project_path" \
      '.projects[$path].hasTrustDialogAccepted == true' \
      "$claude_json" > /dev/null 2>&1; then
    # lock_temp_path is owned by the surrounding with_mkdir_lock subshell.
    # shellcheck disable=SC2154,SC2329
    update_claude_json() {
      if jq -e --arg path "$project_path" \
        '.projects[$path].hasTrustDialogAccepted == true' \
        "$claude_json" > /dev/null 2>&1; then
        return 0
      fi

      lock_temp_file "$claude_json" &&
        jq --arg path "$project_path" \
          '.projects[$path].hasTrustDialogAccepted = true' \
          "$claude_json" > "$lock_temp_path" &&
        mv "$lock_temp_path" "$claude_json"
    }

    with_mkdir_lock "$claude_json.lock" update_claude_json || true
  fi

  # Round-trip through JSON because config.toml has no native jq-like editor.
  # A directory lock prevents concurrent read-modify-write cycles from losing
  # trust entries when several sessions start together.
  if [[ -f "$codex_config" ]] &&
    ! yq -p toml -o json "$codex_config" |
    jq -e --arg path "$project_path" \
      '.projects[$path].trust_level == "trusted"' > /dev/null 2>&1; then
    # lock_temp_path is owned by the surrounding with_mkdir_lock subshell.
    # shellcheck disable=SC2154,SC2329
    update_codex_config() {
      if yq -p toml -o json "$codex_config" |
        jq -e --arg path "$project_path" \
          '.projects[$path].trust_level == "trusted"' > /dev/null 2>&1; then
        return 0
      fi

      lock_temp_file "$codex_config" &&
        yq -p toml -o json "$codex_config" |
        jq --arg path "$project_path" '.projects[$path].trust_level = "trusted"' |
          yq -p json -o toml > "$lock_temp_path" &&
        chmod 600 "$lock_temp_path" &&
        mv "$lock_temp_path" "$codex_config"
    }

    with_mkdir_lock "$codex_config.lock" update_codex_config || true
  fi
}
