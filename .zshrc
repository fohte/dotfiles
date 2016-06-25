# ----------------------------------------------------------
#                      .__
#       ________  _____|  |_________   ____
#       \___   / /  ___/  |  \_  __ \_/ ___\
#        /    /  \___ \|   Y  \  | \/\  \___
#       /_____ \/____  >___|  /__|    \___  >
#             \/     \/     \/            \/   @Fohte
# ----------------------------------------------------------

if [ ! -f ~/.zshrc.zwc ] || [ ~/.zshrc -nt ~/.zshrc.zwc ]; then
    zcompile ~/.zshrc
fi

has() {
  which "$1" > /dev/null 2>&1
  return $?
}

is_osx() {
  [[ $OSTYPE == darwin* ]]
}

if has 'rbenv'; then
  eval "$(rbenv init -)"
fi

if has 'pyenv'; then
  eval "$(pyenv init -)"
fi

if is_osx && has 'brew'; then
  fpath=($(brew --prefix)/share/zsh/site-functions $fpath)
fi

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

ZSHDIR="${HOME}/.zsh"
function source_rc() {
  local source_file="${ZSHDIR}/${1}"

  if [ -f $source_file ]; then
    source $source_file
  fi
}

source_rc 'autoload.rc.zsh'
source_rc 'setopt.rc.zsh'
source_rc 'alias.rc.zsh'
source_rc 'prompt.rc.zsh'
source_rc 'misc.rc.zsh'
