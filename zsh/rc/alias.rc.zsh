alias ls='ls -ACFG'
alias l='ls -l'
alias c='cat'
alias p='pbpaste'
alias x='chmod +x'

has 'gsed' && alias sed='gsed'
has 'gawk' && alias awk='gawk'

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ~='cd ~'
alias /='cd $(git-root || echo $HOME)'
alias u='cd -'
alias q='exit'

has 'hub' && alias git='hub'
alias g='git'
alias ga='git add'
alias gaa='git add -A $(git root)'
alias gap='git add -p'
alias gb='git branch'
alias gbd='git branch -D'
alias gch='git checkout'
alias gcb='git checkout -b'
alias gc='git commit'
alias gca='git add -A $(git root) && git commit'
alias gcm='git commit -m'
alias gcam='git add -A $(git root) && git commit -m'
alias gco='git commit --amend --no-edit'
alias gd='git diff'
alias gds='git diff --staged'
alias gf='git fetch -p'
alias gl='git log --pretty=format:"%Cred%h%Creset - %s%C(yellow)%d%Creset" --graph --abbrev-commit -n 15 --branches'
alias gm='git merge'
alias gms='git merge --ff --squash'
alias gs='git status'
alias gss='git stash save'
alias gsp='git stash pop'
alias gp='git push'
alias gpl='git pull'
alias grb='git rebase'
alias grbi='git rebase -i'
alias gr='git reset'
alias grs='git reset --soft'
alias grh='git reset --hard'

has 'nvim' && alias vim='nvim'
alias v='vim'

alias b='bundle'
alias be='bundle exec'

has 'compose' && alias docker-compose='compose'
alias d='docker'
alias dc='docker-compose'
alias dcr='docker-compose run'
alias dcrm='docker-compose run --rm'
alias dm='docker-machine'

alias y='yarn'
alias yr='yarn run'
alias ya='yarn add'

alias reload='exec $SHELL -l'

alias -g G='| grep'
alias -g GV='| grep -v'
alias -g N='> /dev/null 2>&1'
alias -g Y='| pbcopy'
alias -g M='| more'
alias -g L='| less -R'
alias -g S='| sed'
alias -g J='| jq'

alias -s py=python
alias -s rb=ruby

# make directories and a file
mkdf() {
  dirname=$(dirname $1)
  mkdir -p $dirname
  touch $1
}

mkcd() {
  mkdir -p $@ && cd $@;
}

ghqcd() {
  local dir
  dir="$(ghq root)/$(ghq list | fzf-tmux --reverse)" && cd $dir
}

gocd() {
  local dir
  dir="$(echo $GOPATH/src/*/*/* | perl -pe 's/ /\n/g' | fzf-tmux --reverse)" && cd $dir
}

# switch the tmux session with fzf
fs() {
  local session
  session=$(tmux list-sessions -F "#{session_name}" | \
    fzf --query="$1" --select-1 --exit-0) &&
  tmux switch-client -t "$session"
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
}

has 'tmux-attach' && alias t='tmux-attach'
