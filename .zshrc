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

eval "$(rbenv init -)"
eval "$(pyenv init -)"

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

ZSHDIR="${HOME}/.zsh"
function source_rc() {
  local source_file="${ZSHDIR}/${1}"

  if [ -f $source_file ]; then
    source $source_file
  fi
}

fpath=($(brew --prefix)/share/zsh/site-functions $fpath)

source_rc 'autoload.rc.zsh'
source_rc 'setopt.rc.zsh'
source_rc 'alias.rc.zsh'
source_rc 'prompt.rc.zsh'
source_rc 'misc.rc.zsh'
