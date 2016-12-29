# ----------------------------------------------------------
#                      .__
#       ________  _____|  |_________   ____
#       \___   / /  ___/  |  \_  __ \_/ ___\
#        /    /  \___ \|   Y  \  | \/\  \___
#       /_____ \/____  >___|  /__|    \___  >
#             \/     \/     \/            \/   @Fohte
# ----------------------------------------------------------

source `lib util`

source_rc() {
  local source_file="$ZSHDIR/$1"

  if [ -f $source_file ]; then
    source $source_file
  fi
}

has 'rbenv' && eval "$(rbenv init -)"
has 'pyenv' && eval "$(pyenv init -)"

# Setup GnuPG Agent (gpg-agent)
if [ -f ~/.gnupg/.gpg-agent-info ] && [ -n "$(pgrep gpg-agent)" ]; then
  source ~/.gnupg/.gpg-agent-info
  export GPG_AGENT_INFO
else
  eval $(gpg-agent --daemon --write-env-file ~/.gnupg/.gpg-agent-info)
fi
export GPG_TTY=`tty`

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

autoload -Uz compinit && compinit -u
autoload -Uz colors; colors

source_rc 'setopt.rc.zsh'
source_rc 'alias.rc.zsh'
source_rc 'prompt.rc.zsh'
source_rc 'misc.rc.zsh'
