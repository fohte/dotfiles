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
  local query="SELECT h.id || '  ' || c.argv
               FROM history h
               JOIN commands c ON h.command_id = c.id
               JOIN places p ON h.place_id = p.id
               WHERE p.host = '$(hostname)'
               ORDER BY h.start_time DESC
               LIMIT 1000"

  # from original fzf-history-widget (fzf --zsh)
  # Added preview window with syntax highlighting using bat
  selected=$(_histdb_query "$query" |
    FZF_DEFAULT_OPTS=$(__fzf_defaults "" "-n2..,.. --scheme=history --bind=ctrl-r:toggle-sort --wrap-sign '\t↳ ' --highlight-line ${FZF_CTRL_R_OPTS-} --query=${(qqq)LBUFFER} +m --preview 'echo {2..} | bat --color=always --style=plain --language=zsh' --preview-window=bottom:3:wrap") \
    FZF_DEFAULT_OPTS_FILE='' $(__fzfcmd))

  local ret=$?
  if [ -n "$selected" ]; then
    # Remove the ID prefix and use the command
    local cmd="${selected#*  }"
    if [ -n "$cmd" ]; then
      BUFFER="$cmd"
      CURSOR=$#BUFFER
    fi
  fi
  zle reset-prompt
  return $ret
}
