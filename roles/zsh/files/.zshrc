# ----------------------------------------------------------
#                      .__
#       ________  _____|  |_________   ____
#       \___   / /  ___/  |  \_  __ \_/ ___\
#        /    /  \___ \|   Y  \  | \/\  \___
#       /_____ \/____  >___|  /__|    \___  >
#             \/     \/     \/            \/   @Fohte
# ----------------------------------------------------------

import_rc() {
  local source_file="$HOME/.zsh/$1.rc.zsh"

  if [ -f $source_file ]; then
    source $source_file
  fi
}

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

autoload -Uz compinit && compinit -u
autoload -Uz colors; colors

[ -d ~/.zinit ] && import_rc 'zinit'

import_rc 'lazy'
import_rc 'alias'
import_rc 'bindkey'
import_rc 'prompt'
import_rc 'history'
import_rc 'misc'

[ -f ~/.local/.zshrc ] && source ~/.local/.zshrc
