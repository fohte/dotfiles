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

  # Build directory priority CASE statement for SQL
  local pwd_clean="${PWD:a}"  # Resolve symlinks
  local -a dir_levels=()
  local current_path="$pwd_clean"

  # Build array of directory paths from current to root
  while [[ "$current_path" != "/" ]]; do
    dir_levels+=("$current_path")
    current_path="${current_path:h}"
  done

  # Build CASE statement for directory priority
  # Lower number = higher priority (closer to current directory)
  local priority_case="CASE"
  local priority=0
  for dir in "${dir_levels[@]}"; do
    priority_case+="
      WHEN p.dir = '${dir}' THEN ${priority}"
    ((priority++))

    # Also match subdirectories of parent directories (with same priority as parent)
    if [[ $priority -gt 1 ]]; then
      priority_case+="
      WHEN p.dir LIKE '${dir}/%' THEN ${priority}"
    fi
  done
  priority_case+="
      ELSE 1000
    END"

  # Build history query with filter type (all, success, failed)
  _build_history_query() {
    local filter_type="$1"
    local where_clause=""

    case "$filter_type" in
      success)
        where_clause="WHERE h.exit_status = 0"
        ;;
      failed)
        where_clause="WHERE h.exit_status IS NOT NULL AND h.exit_status != 0"
        ;;
      all)
        where_clause=""
        ;;
    esac

    cat <<-EOF
	SELECT h.id || CHAR(9) || REPLACE(c.argv, CHAR(10), ' ')
	FROM history h
	JOIN commands c ON h.command_id = c.id
	JOIN places p ON h.place_id = p.id
	${where_clause}
	GROUP BY c.argv
	ORDER BY
	  COUNT(h.id) DESC,
	  MIN(${priority_case}),
	  MAX(h.start_time) DESC
	LIMIT 1000
	EOF
  }

  local query_all=$(_build_history_query "all")
  local query_success=$(_build_history_query "success")
  local query_failed=$(_build_history_query "failed")

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
    --delimiter=$'\t'  # Use TAB as delimiter to separate ID and command
    --header "C-s: ${c_green}Success${c_reset} | C-f: Failed | C-r: All"
    --preview "${preview_cmd}"
    --preview-window=bottom:3:wrap
    --bind "ctrl-f:change-header(C-s: Success | C-f: ${c_red}Failed${c_reset} | C-r: All)+reload:sqlite3 \$HISTDB_FILE \$HISTDB_QUERY_FAILED | bat --color=always --style=plain --language=zsh --paging=never 2>/dev/null"
    --bind "ctrl-s:change-header(C-s: ${c_green}Success${c_reset} | C-f: Failed | C-r: All)+reload:sqlite3 \$HISTDB_FILE \$HISTDB_QUERY_SUCCESS | bat --color=always --style=plain --language=zsh --paging=never 2>/dev/null"
    --bind "ctrl-r:change-header(C-s: Success | C-f: Failed | C-r: ${c_cyan}All${c_reset})+reload:sqlite3 \$HISTDB_FILE \$HISTDB_QUERY_ALL | bat --color=always --style=plain --language=zsh --paging=never 2>/dev/null"
    # --with-nth=2.. hides the id from display (but preview can still access it via {1})
    --with-nth=2.. --ansi --scheme=history
    --wrap-sign $'\t↳ ' --highlight-line
    +m
  )

  # Add --query only if LBUFFER is not empty
  [[ -n "$LBUFFER" ]] && fzf_opts+=(--query "$LBUFFER")

  selected=$(
    sqlite3 "${histdb_file}" "${query_success}" | \
    bat --color=always --style=plain --language=zsh --paging=never 2>/dev/null | \
    env \
    HISTDB_FILE="${histdb_file}" \
    HISTDB_QUERY_ALL="${query_all}" \
    HISTDB_QUERY_SUCCESS="${query_success}" \
    HISTDB_QUERY_FAILED="${query_failed}" \
    $(__fzfcmd) "${fzf_opts[@]}"
  )

  local ret=$?
  if [ -n "$selected" ]; then
    # Extract ID from the first field (TAB-separated)
    local id="${selected%%$'\t'*}"
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
