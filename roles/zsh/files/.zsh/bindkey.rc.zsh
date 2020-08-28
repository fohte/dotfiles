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

function expand-alias-for-enter() {
  zle _expand_alias
  zle .accept-line
}

zle -N accept-line expand-alias-for-enter
