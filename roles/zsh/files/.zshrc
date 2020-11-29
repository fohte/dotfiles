# ----------------------------------------------------------
#                      .__
#       ________  _____|  |_________   ____
#       \___   / /  ___/  |  \_  __ \_/ ___\
#        /    /  \___ \|   Y  \  | \/\  \___
#       /_____ \/____  >___|  /__|    \___  >
#             \/     \/     \/            \/   @Fohte
# ----------------------------------------------------------

import_rc() {
  local source_file="$ZSHRC_ROOT/$1"

  if [ -f $source_file ]; then
    source $source_file
  fi
}

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

autoload -Uz compinit && compinit -u
autoload -Uz colors; colors

if ! [ -d ~/.zinit ]; then
  import_rc 'install/zinit.zsh'
fi

import_rc 'zinit.rc.zsh'

import_rc 'lazy.rc.zsh'
import_rc 'alias.rc.zsh'
import_rc 'bindkey.rc.zsh'
import_rc 'prompt.rc.zsh'
import_rc 'history.rc.zsh'
import_rc 'misc.rc.zsh'

[ -f ~/.local/.zshrc ] && source ~/.local/.zshrc

# The next line updates PATH for Netlify's Git Credential Helper.
if [ -f '/home/fohte/.netlify/helper/path.zsh.inc' ]; then source '/home/fohte/.netlify/helper/path.zsh.inc'; fi
