alias ls='ls -ACFG'
alias l='ls -l'
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

mkcd() {
  mkdir -p $@ && cd $@;
}

ghqcd() {
  cd $(ghq root)/$(ghq list | fzf-tmux --reverse)
}

gaf() {
  local addfiles
  addfiles=($(git status --short | grep -v '##' | awk '{ print $2 }' | fzf-tmux --multi))
  if [[ -n $addfiles ]]; then
    git add ${@:1} $addfiles && echo "added: $addfiles"
  else
    echo "nothing added."
  fi
}
