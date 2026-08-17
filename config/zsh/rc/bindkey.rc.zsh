bindkey '^?' backward-delete-char

import_rc 'bindkey/vimode.rc.zsh'
import_rc 'bindkey/fzf.rc.zsh'

bindkey '^P' up-history
bindkey '^N' down-history

function expand-alias() {
  zle _expand_alias
  zle self-insert
}

zle -N expand-alias
bindkey -M main ' ' expand-alias

function custom-accept-line() {
  # if buffer is empty and we're in a git repository, run git status
  if [[ -z "$BUFFER" ]] && git rev-parse --is-inside-work-tree &> /dev/null; then
    BUFFER="git status"
  fi

  # expand aliases
  zle _expand_alias

  # re-render the prompt
  zle .reset-prompt

  zle .accept-line
}

zle -N accept-line custom-accept-line
