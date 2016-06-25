alias ls='ls -ACFG'
alias g='git'
alias v='nvim'
alias be='bundle exec'
alias d='docker'
alias dc='docker-compose'
alias dcr='docker-compose run'
alias dm='docker-machine'

alias -g G='| grep'
alias -g N='> /dev/null 2>&1'
alias -g Y='| pbcopy'
alias -g M='| more'
alias -g L='| less'

alias -s py=python
alias -s rb=ruby

function mkcd() {
  mkdir -p $@ && $@;
}

ghqcd() {
  cd $(ghq root)/$(ghq list | fzf-tmux --reverse)
}
