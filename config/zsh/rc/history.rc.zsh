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

# Use histdb with fzf for Ctrl-R (override default fzf-history-widget)
fzf-history-widget() {
  local selected

  _histdb_init
  # Modified query to get unique commands, showing the most recent execution of each
  # Replace newlines with space for single-line display in fzf
  local query=$(cat <<-EOF
	SELECT MAX(h.id) || '  ' || REPLACE(c.argv, CHAR(10), ' ')
	FROM history h
	JOIN commands c ON h.command_id = c.id
	JOIN places p ON h.place_id = p.id
	WHERE p.host = '$(hostname)'
	GROUP BY c.argv
	ORDER BY MAX(h.start_time) DESC
	LIMIT 1000
	EOF
  )

  # Store the database path for preview command
  local histdb_file="${HISTDB_FILE:-${HOME}/.histdb/zsh-history.db}"

  # Create preview command
  local preview_cmd="sqlite3 '${histdb_file}' 'SELECT c.argv FROM history h JOIN commands c ON h.command_id = c.id WHERE h.id = {1}' | bat --color=always --style=plain --language=zsh --paging=never"
  
  # Get all history and apply bat highlighting in batch
  selected=$(
    _histdb_query "$query" | \
    bat --color=always --style=plain --language=zsh --paging=never 2>/dev/null | \
    FZF_DEFAULT_OPTS=$(__fzf_defaults "" "-n2..,.. --ansi --scheme=history --bind=ctrl-r:toggle-sort --wrap-sign '\t↳ ' --highlight-line ${FZF_CTRL_R_OPTS-} --query=${(qqq)LBUFFER} +m") \
    FZF_DEFAULT_OPTS_FILE='' \
    $(__fzfcmd) --preview "${preview_cmd}" --preview-window=bottom:3:wrap)

  local ret=$?
  if [ -n "$selected" ]; then
    # Get the actual command (with newlines) from the database using the ID
    local id=$(echo "$selected" | awk '{print $1}')
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
