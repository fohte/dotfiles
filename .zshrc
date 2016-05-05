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

fpath=($(brew --prefix)/share/zsh/site-functions $fpath)

autoload -Uz add-zsh-hook

# ----------------------------------------------------------
#   Prompt
# ----------------------------------------------------------
autoload -Uz vcs_info
setopt prompt_subst

zstyle ':vcs_info:git:*' max-exports 1
zstyle ':vcs_info:git:*' check-for-changes true

zstyle ':vcs_info:git:*' stagedstr '*'
zstyle ':vcs_info:git:*' unstagedstr '*'

zstyle ':vcs_info:git:*' formats '%F{red}%u%f%F{yellow}%c%f%F{black}(%m)%f %F{green}%b%f'
zstyle ':vcs_info:git:*' actionformats '%F{red}%u%f%F{yellow}%c%f%F{black}(%m)%f [%a] %F{green}%b%f'

zstyle ':vcs_info:git+set-message:*' hooks \
  git-hooks-begin \
  git-unpushed \
  git-stash-count \

function +vi-git-hooks-begin() {
  if [[ $(git rev-parse --is-inside-work-tree 2> /dev/null) != 'true' ]]; then
    return 1
  fi

  hook_com[branch]="${hook_com[branch]}"
  hook_com[misc]=''

  return 0
}

function +vi-git-unpushed() {
  if [[ $(git status -b --porcelain 2> /dev/null | grep '##' | awk '{ print $3 }') = '[ahead' ]]; then

    hook_com[branch]='%F{red}↑%f'${hook_com[branch]}
  fi
}

function +vi-git-stash-count() {
  local stash
  stash_count=$(git stash list 2>/dev/null | wc -l | tr -d ' ')

  if [[ ${stash_count} -gt 0 ]]; then
    hook_com[misc]+=${stash_count}
  fi
}


add-zsh-hook precmd vcs_info

PROMPT='%F{black}%n@%m%f %# '
RPROMPT='${vcs_info_msg_0_}'


# ----------------------------------------------------------
#   Alias
# ----------------------------------------------------------
alias ls='ls -ACFG'
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
alias -g L='| less'

function mkcd() {
  mkdir -p $@ && $@;
}

alias -s py=python
alias -s rb=ruby


# ----------------------------------------------------------
#   Utils
# ----------------------------------------------------------
do_enter() {
  if [[ -n "$BUFFER" ]]; then
    zle accept-line
    return 0
  fi

  echo
  pwd

  echo
  ls

  if [ "$(git rev-parse --is-inside-work-tree 2> /dev/null)" = 'true' ]; then
    echo
    git status --short --branch
  fi

  zle reset-prompt
  return 0
}
zle -N do_enter
bindkey "^m" do_enter


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
