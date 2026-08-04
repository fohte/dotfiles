# ----------------------------------------------------------
#                      .__
#       ________  _____|  |_________   ____
#       \___   / /  ___/  |  \_  __ \_/ ___\
#        /    /  \___ \|   Y  \  | \/\  \___
#       /_____ \/____  >___|  /__|    \___  >
#             \/     \/     \/            \/   @Fohte
# ----------------------------------------------------------

import_rc() {
  import_zsh_config "$ZSH_CONFIG_HOME/rc/$1"
}

# Skip fpath rescan if .zcompdump was updated within the last 24h
autoload -Uz compinit
() {
  setopt local_options extended_glob
  local zcompdump="${ZDOTDIR:-$HOME}/.zcompdump"
  if [[ -f $zcompdump && -z $zcompdump(#qN.mh+24) ]]; then
    compinit -C -u -d "$zcompdump"
  else
    compinit -u -d "$zcompdump"
  fi
}
autoload -Uz colors
colors

if ! [ -d ~/.zinit ]; then
  import_rc 'install/zinit.zsh'
fi

import_rc 'zinit.rc.zsh'

import_rc 'alias.rc.zsh'
import_rc 'bindkey.rc.zsh'
import_rc 'completions.rc.zsh'
import_rc 'prompt.rc.zsh'
import_rc 'history.rc.zsh'
import_rc 'misc.rc.zsh'
import_rc 'tmux.rc.zsh'

# Role-specific overlay (private: in-repo, work: external repo). The symlink
# is pre-resolved by `dot deploy` to avoid shelling out to `dot role` here.
[ -f "$ZDOTDIR/.zshrc.overlay" ] && source "$ZDOTDIR/.zshrc.overlay"

[ -f ~/.local/.zshrc ] && source ~/.local/.zshrc

() {
  # `starship init` bakes the path it was invoked with into PROMPT/RPROMPT, so
  # resolving to the mise shim — a symlink to the mise binary — makes every
  # prompt exec mise twice before starship even starts. Glob the installs dir
  # for the real binary rather than trusting whatever `command -v` finds.
  local -a matches=(${MISE_DATA_DIR}/installs/aqua-starship-starship/*/starship(NOn))
  local starship_bin="${matches[1]:-$(command -v starship)}"
  [[ -n $starship_bin ]] || return
  cache_source starship-init "$starship_bin" -- "$starship_bin" init zsh
}
