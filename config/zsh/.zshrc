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

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

autoload -Uz compinit && compinit -u
autoload -Uz colors; colors
autoload -U +X bashcompinit && bashcompinit
complete -C "$(which aws_completer)" aws

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

import_rc 'plugins/op.rc.zsh'

[ -f ~/.local/.zshrc ] && source ~/.local/.zshrc
