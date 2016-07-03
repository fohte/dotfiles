# ----------------------------------------------------------
#                      .__
#       ________  _____|  |_________   ____
#       \___   / /  ___/  |  \_  __ \_/ ___\
#        /    /  \___ \|   Y  \  | \/\  \___
#       /_____ \/____  >___|  /__|    \___  >
#             \/     \/     \/            \/   @Fohte
# ----------------------------------------------------------

source_rc() {
  local source_file="$ZSHDIR/$1"

  if [ -f $source_file ]; then
    source $source_file
  fi
}

source_rc 'functions.rc.zsh'

has 'rbenv' && eval "$(rbenv init -)"
has 'pyenv' && eval "$(pyenv init -)"


[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

source_rc 'autoload.rc.zsh'
source_rc 'setopt.rc.zsh'
source_rc 'alias.rc.zsh'
source_rc 'prompt.rc.zsh'
source_rc 'misc.rc.zsh'
