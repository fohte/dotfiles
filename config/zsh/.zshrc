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
autoload -Uz colors; colors

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

# Role-specific overlay (private: in-repo, work: external repo). See `dot role`.
if _zshrc_overlay="$(dot role overlay "$ZDOTDIR/.zshrc" 2> /dev/null)"; then
  source "$_zshrc_overlay"
fi
unset _zshrc_overlay

[ -f ~/.local/.zshrc ] && source ~/.local/.zshrc

eval "$(starship init zsh)"
