alias ls='ls -ACFG'
alias l='ls -l'

has 'hub' && alias git='hub'
alias g='git'

has 'nvim' && alias vim='nvim'
alias v='vim'

alias be='bundle exec'

alias d='docker'
alias dc='docker-compose'
alias dcr='docker-compose run'
alias dm='docker-machine'

alias -g G='| grep'
alias -g GV='| grep -v'
alias -g N='> /dev/null 2>&1'
alias -g Y='| pbcopy'
alias -g M='| more'
alias -g L='| less -R'

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

# search and execute command from history with fzf
fh() {
  eval $( ([ -n "$ZSH_NAME" ] && fc -l 1 || history) | fzf-tmux +s --tac | sed 's/ *[0-9]* *//')
}
}

ghq-init() {
  root=$(ghq root)
  user=$(git config --get github.user)
  if [ -z "$user" ]; then
    echo "you need to set github.user."
    echo "git config --global github.user YOUR_GITHUB_USER_NAME"
    exit 1
  fi
  name=$1
  repo="$root/github.com/$user/$name"
  if [ -e "$repo" ]; then
    echo "$repo is already exists."
    exit 1
  fi
  git init $repo
  cd $repo
  touch README.md
}
