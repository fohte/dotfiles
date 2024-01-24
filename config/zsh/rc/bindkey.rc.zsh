bindkey '^?' backward-delete-char

import_rc 'bindkey/vimode.rc.zsh'
import_rc 'bindkey/fzf.rc.zsh'

bindkey '^P' up-history
bindkey '^N' down-history

no_expand_commands=(
  # these commands should not be expanded because they are aliased by the op plugin.
  aws
  gh
)

function ignore-expansion() {
  local cmd="${BUFFER%% *}"

  # check if the command is in the no_expand_commands array
  (( ${no_expand_commands[(Ie)$cmd]} ))
}

function expand-alias() {
  ! ignore-expansion && zle _expand_alias
  zle self-insert
}

zle -N expand-alias
bindkey -M main ' ' expand-alias

function custom-accept-line() {
  # expand aliases
  ! ignore-expansion && zle _expand_alias

  # re-render the prompt
  zle .reset-prompt

  zle .accept-line
}

zle -N accept-line custom-accept-line
