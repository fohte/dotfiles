# ----------------------------------------------------------
#                      .__
#       ________  _____|  |_________   ____
#       \___   / /  ___/  |  \_  __ \_/ ___\
#        /    /  \___ \|   Y  \  | \/\  \___
#       /_____ \/____  >___|  /__|    \___  >
#             \/     \/     \/            \/   @Fohte
# ----------------------------------------------------------

. "$DOTPATH"/bin/lib/util.sh

source_rc() {
  local source_file="$DOTPATH/zsh/rc/$1"

  if [ -f $source_file ]; then
    source $source_file
  fi
}

has 'rbenv' && eval "$(rbenv init - --no-rehash)"
has 'pyenv' && eval "$(pyenv init - --no-rehash)"

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

autoload -Uz compinit && compinit -u
autoload -Uz colors; colors

source_rc 'setopt.rc.zsh'
source_rc 'alias.rc.zsh'
source_rc 'bindkey.rc.zsh'
source_rc 'prompt.rc.zsh'
source_rc 'misc.rc.zsh'

[ -f ~/.local/.zshrc ] && source ~/.local/.zshrc
