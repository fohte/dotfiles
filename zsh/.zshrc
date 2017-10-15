# ----------------------------------------------------------
#                      .__
#       ________  _____|  |_________   ____
#       \___   / /  ___/  |  \_  __ \_/ ___\
#        /    /  \___ \|   Y  \  | \/\  \___
#       /_____ \/____  >___|  /__|    \___  >
#             \/     \/     \/            \/   @Fohte
# ----------------------------------------------------------

. "$DOTPATH"/bin/lib/util.sh

import_rc() {
  local source_file="$DOTPATH/zsh/rc/$1.rc.zsh"

  if [ -f $source_file ]; then
    source $source_file
  fi
}

has 'rbenv' && eval "$(rbenv init - --no-rehash)"
has 'pyenv' && eval "$(pyenv init - --no-rehash)"

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

autoload -Uz compinit && compinit -u
autoload -Uz colors; colors

if [ ! -d ~/.zplug ]; then
  printf 'Install zplug? [y/N]: '
  if read -q; then
    echo
    curl -sL --proto-redir -all,https \
      https://raw.githubusercontent.com/zplug/installer/master/installer.zsh | zsh
  fi
fi
[ -d ~/.zplug ] && import_rc 'zplug'

import_rc 'alias'
import_rc 'bindkey'
import_rc 'prompt'
import_rc 'history'
import_rc 'misc'

[ -f ~/.local/.zshrc ] && source ~/.local/.zshrc
