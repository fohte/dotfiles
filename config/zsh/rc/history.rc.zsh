setopt hist_ignore_all_dups
setopt hist_reduce_blanks
setopt share_history

zshaddhistory() {
  local line=${1%%$'\n'}

  # Ignore 4 or less letters command
  [[ ${#line} -ge 5 ]]
}

# zsh-histdb configuration
export HISTDB_FILE="${HOME}/.histdb/zsh-history.db"

# Custom query aliases for zsh-histdb
alias histdb-recent='histdb --limit 30 --no-host'
alias histdb-pwd='histdb --limit 30 --no-host -d "$(pwd)"'
alias histdb-search='histdb --no-host'

# Wrap histdb's _histdb_addhistory to apply hist_reduce_blanks behavior
if (( ${+functions[_histdb_addhistory]} )); then
  # Save original function
  functions[_histdb_addhistory_original]=${functions[_histdb_addhistory]}

  # Wrap it with cleanup logic
  _histdb_addhistory() {
    local cmd="${1[0, -2]}"

    # Apply hist_reduce_blanks equivalent using zsh parameter expansion
    if [[ -o histreduceblanks ]]; then
      setopt local_options extended_glob
      cmd="${cmd//$'\n'/ }"              # newline to space
      cmd="${cmd//[[:space:]]##/ }"      # multiple spaces to one
      cmd="${cmd##[[:space:]]##}"        # trim start
      cmd="${cmd%%[[:space:]]##}"        # trim end
    fi

    # Call original function with cleaned string
    _histdb_addhistory_original "$cmd"$'\n'
  }
fi

# Use histdb with fzf for Ctrl-R (override default fzf-history-widget)
fzf-history-widget() {
  local selected

  _histdb_init

  # Query to get ID
  local query_id_status_base="
    SELECT h.id
    FROM history h
    JOIN commands c ON h.command_id = c.id
    JOIN places p ON h.place_id = p.id
    WHERE p.host = '$(hostname)'"

  # Query to get commands (for syntax highlighting)
  local query_cmd_base="
    SELECT REPLACE(c.argv, CHAR(10), ' ')
    FROM history h
    JOIN commands c ON h.command_id = c.id
    JOIN places p ON h.place_id = p.id
    WHERE p.host = '$(hostname)'"

  # Query variations for filtering
  local group_order="
    GROUP BY c.argv
    ORDER BY MAX(h.start_time) DESC
    LIMIT 1000"

  local query_id_status_all="${query_id_status_base} ${group_order}"
  local query_cmd_all="${query_cmd_base} ${group_order}"

  local filter_success=" AND h.exit_status = 0"
  local query_id_status_success="${query_id_status_base}${filter_success} ${group_order}"
  local query_cmd_success="${query_cmd_base}${filter_success} ${group_order}"

  local filter_failed=" AND h.exit_status IS NOT NULL AND h.exit_status != 0"
  local query_id_status_failed="${query_id_status_base}${filter_failed} ${group_order}"
  local query_cmd_failed="${query_cmd_base}${filter_failed} ${group_order}"

  # Store the database path for preview command
  local histdb_file="${HISTDB_FILE:-${HOME}/.histdb/zsh-history.db}"

  # Create preview command
  local preview_cmd=$(cat <<-EOF
	sqlite3 '${histdb_file}' \\
	  'SELECT c.argv FROM history h JOIN commands c ON h.command_id = c.id WHERE h.id = {1}' \\
	| bat --color=always --style=plain --language=zsh --paging=never
	EOF
  )

  # ANSI color codes for header
  local c_reset=$'\033[0m'
  local c_green=$'\033[1;32m'
  local c_red=$'\033[1;31m'
  local c_cyan=$'\033[1;36m'

  # Build fzf options array
  local fzf_opts=(
    --header "C-s: ${c_green}Success${c_reset} | C-f: Failed | C-r: All"
    --preview "${preview_cmd}"
    --preview-window=bottom:3:wrap
    --bind "ctrl-f:change-header(C-s: Success | C-f: ${c_red}Failed${c_reset} | C-r: All)+reload:paste -d' ' <(sqlite3 \$HISTDB_FILE \$HISTDB_QUERY_ID_STATUS_FAILED) <(sqlite3 \$HISTDB_FILE \$HISTDB_QUERY_CMD_FAILED | bat --color=always --style=plain --language=zsh --paging=never 2>/dev/null)"
    --bind "ctrl-s:change-header(C-s: ${c_green}Success${c_reset} | C-f: Failed | C-r: All)+reload:paste -d' ' <(sqlite3 \$HISTDB_FILE \$HISTDB_QUERY_ID_STATUS_SUCCESS) <(sqlite3 \$HISTDB_FILE \$HISTDB_QUERY_CMD_SUCCESS | bat --color=always --style=plain --language=zsh --paging=never 2>/dev/null)"
    --bind "ctrl-r:change-header(C-s: Success | C-f: Failed | C-r: ${c_cyan}All${c_reset})+reload:paste -d' ' <(sqlite3 \$HISTDB_FILE \$HISTDB_QUERY_ID_STATUS_ALL) <(sqlite3 \$HISTDB_FILE \$HISTDB_QUERY_CMD_ALL | bat --color=always --style=plain --language=zsh --paging=never 2>/dev/null)"
    # --with-nth=2.. hides the id from display (but preview can still access it via {1})
    # --accept-nth=1 outputs the id on selection (references original line, not transformed)
    --with-nth=2.. --accept-nth=1 --ansi --scheme=history
    --wrap-sign $'\t↳ ' --highlight-line
    +m
  )

  # Add --query only if LBUFFER is not empty
  [[ -n "$LBUFFER" ]] && fzf_opts+=(--query "$LBUFFER")

  selected=$(
    paste -d' ' \
      <(sqlite3 "${histdb_file}" "${query_id_status_success}") \
      <(sqlite3 "${histdb_file}" "${query_cmd_success}" | bat --color=always --style=plain --language=zsh --paging=never 2>/dev/null) | \
    env \
    HISTDB_FILE="${histdb_file}" \
    HISTDB_QUERY_ID_STATUS_ALL="${query_id_status_all}" \
    HISTDB_QUERY_CMD_ALL="${query_cmd_all}" \
    HISTDB_QUERY_ID_STATUS_SUCCESS="${query_id_status_success}" \
    HISTDB_QUERY_CMD_SUCCESS="${query_cmd_success}" \
    HISTDB_QUERY_ID_STATUS_FAILED="${query_id_status_failed}" \
    HISTDB_QUERY_CMD_FAILED="${query_cmd_failed}" \
    $(__fzfcmd) "${fzf_opts[@]}"
  )

  local ret=$?
  if [ -n "$selected" ]; then
    # Get the actual command (with newlines) from the database using the ID
    # --accept-nth=1 returns only the id
    local id="$selected"
    if [ -n "$id" ]; then
      local cmd=$(_histdb_query "SELECT c.argv FROM history h JOIN commands c ON h.command_id = c.id WHERE h.id = $id")
      if [ -n "$cmd" ]; then
        BUFFER="$cmd"
        CURSOR=$#BUFFER
      fi
    fi
  fi
  zle reset-prompt
  return $ret
}
