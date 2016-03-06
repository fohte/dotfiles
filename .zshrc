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

export PATH="usr/local/bin:$PATH"

# rbenv
export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"

# pyenv
export PATH="$HOME/.pyenv/shims:$PATH"
eval "$(pyenv init -)"

# neovim
export XDG_CONFIG_HOME=~/.config

fpath=($(brew --prefix)/share/zsh/site-functions $fpath)

autoload -Uz add-zsh-hook

# ----------------------------------------------------------
#   Prompt
# ----------------------------------------------------------
autoload -Uz vcs_info
setopt prompt_subst

_fg_color() { echo "%{[38;5;$1m%}" }
_bg_color() { echo "%{[48;5;$1m%}" }
_reset_color() { echo "%{[0m%}" }
_reset_fg_color() { echo "%{[39m%}" }
_reset_bg_color() { echo "%{[49m%}" }

typeset -a prompt_bg_colors
prompt_bg_colors=(235 240)

typeset -a prompt_fg_colors
prompt_fg_colors=(178 007)

typeset -a prompt_texts
prompt_texts=("%n@%m" "%~")

PROMPT=""
RPROMPT=""

zstyle ':vcs_info:git:*' check-for-changes true
zstyle ':vcs_info:git:*' stagedstr "`_fg_color 011`⮂`_bg_color 011``_fg_color 233` ! "
zstyle ':vcs_info:git:*' unstagedstr "`_fg_color 088`⮂`_bg_color 088``_reset_fg_color` + "
zstyle ':vcs_info:*' formats "`_fg_color 240`⮂`_bg_color 240``_reset_fg_color` %b %c%u"
add-zsh-hook precmd vcs_info

RPROMPT='${vcs_info_msg_0_}'`_reset_color`

for i in {1..$#prompt_texts}; do
  PROMPT+="`_bg_color $prompt_bg_colors[i]``_fg_color $prompt_fg_colors[i]` ${prompt_texts[i]} "
  if [[ i -eq $#prompt_texts ]]; then
    PROMPT+=`_reset_bg_color`
  else
    PROMPT+="`_bg_color $prompt_bg_colors[i+1]`"
  fi
  PROMPT+="`_fg_color $prompt_bg_colors[i]`⮀"
done

PROMPT+="`_reset_color` "


# ----------------------------------------------------------
#   Alias
# ----------------------------------------------------------
alias ls='ls -aCFG'
alias be='bundle exec'
alias g='git'
alias v='nvim'
alias vi='nvim'
alias vim='nvim'
alias d='docker'
alias dc='docker-compose'
alias dcr='docker-compose run'
alias dm='docker-machine'

alias -g G='| grep'
alias -g N='> /dev/null 2>&1'
alias -g Y='| pbcopy'
alias -g M='| more'

function mkcd() {
  mkdir -p $@ && $@;
}


# ----------------------------------------------------------
#   Completion
# ----------------------------------------------------------
autoload -U compinit
compinit -u

setopt menu_complete

export WORDCHARS="*?_-.[]~=&;!#$%^(){}<>+"

zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'


# ----------------------------------------------------------
#   History
# ----------------------------------------------------------
setopt hist_ignore_dups
setopt hist_reduce_blanks
setopt share_history

export HISTFILE=${HOME}/.zsh_history
export HISTSIZE=1000
export SAVEHIST=100000


# ----------------------------------------------------------
#   Other Options
# ----------------------------------------------------------
setopt auto_cd
setopt ignore_eof
setopt rm_star_wait
