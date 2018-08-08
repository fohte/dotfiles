alias c='cat'
alias l='ls -l'
alias ls='ls -ACFG'
alias p='pbpaste'
alias x='chmod +x'

has 'gsed' && alias sed='gsed'
has 'gawk' && alias awk='gawk'

alias ....='cd ../../..'
alias ...='cd ../..'
alias ..='cd ..'
alias /='cd $(git-root || echo $HOME)'
alias q='exit'
alias u='cd -'
alias ~='cd ~'

has 'hub' && alias git='hub'

alias g='git'
alias ga='git add'
alias gaa='git add -A $(git root)'
alias gap='git add -p'
alias gb='git branch'
alias gbd='git branch -D'
alias gc='git commit'
alias gca='git add -A $(git root) && git commit'
alias gcam='git add -A $(git root) && git commit -m'
alias gcb='git checkout -b'
alias gch='git checkout'
alias gcm='git commit -m'
alias gco='git commit --amend --no-edit'
alias gd='git diff'
alias gds='git diff --staged'
alias gf='git fetch -p'
alias gl='git log --pretty=format:"%Cred%h%Creset - %s%C(yellow)%d%Creset" --graph --abbrev-commit -n 15 --branches'
alias gm='git merge'
alias gms='git merge --ff --squash'
alias gnb='git new-branch'
alias gnw='git-new-worktree'
alias gp='git push'
alias gpl='git pull'
alias gr='git reset'
alias grb='git rebase'
alias grbi='git rebase -i'
alias grh='git reset --hard'
alias grs='git reset --soft'
alias gs='git status'
alias gsp='git stash pop'
alias gss='git stash save'
alias gw='git worktree'

git-new-worktree() {
  set -x
  git worktree add "$(git root)/.worktrees/$1" "$1"
}

has 'nvim' && alias vim='nvim'

alias v='vim'

alias b='bundle'
alias be='bundle exec'

has 'compose' && alias docker-compose='compose'

alias d='docker'
alias dc='docker-compose'
alias dce='docker-compose exec'
alias dcr='docker-compose run'
alias dcrm='docker-compose run --rm'
alias dm='docker-machine'
alias dr='docker run'
alias drm='docker run --rm'
alias drmit='docker run --rm -it'

alias y='yarn'
alias ya='yarn add'
alias yr='yarn run'

alias n='npm'
alias ni='npm install'
alias nid='npm install -D'
alias nr='npm run'

alias tf='terraform'

alias reload='exec $SHELL -l'

alias -g F='| fzf-tmux --multi'
alias -g G='| grep'
alias -g GV='| grep -v'
alias -g J='| jq'
alias -g L='| less -R'
alias -g M='| more'
alias -g N='> /dev/null 2>&1'
alias -g S='| sed'
alias -g X='| xargs -I%'
alias -g XP='X -P "$(ncpu)"'
alias -g Y='| pbcopy'

alias -s py=python
alias -s rb=ruby

mkcd() {
  mkdir -p $@ && cd $@;
}

ghqcd() {
  local dir
  dir="$(ghq list -p | sed "s/^${HOME//\//\\/}/~/g" | fzf-tmux --reverse)" && cd $dir
}

gwcd() {
  local dir
  dir="$(git worktree list | awk '{ print $1 }' | fzf-tmux --reverse)" && cd $dir
}

gocd() {
  local dir
  dir="$(echo $GOPATH/src/*/*/* | perl -pe 's/ /\n/g' | fzf-tmux --reverse)" && cd $dir
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
