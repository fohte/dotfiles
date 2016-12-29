alias ls='ls -ACFG'
alias l='ls -l'

has 'hub' && alias git='hub'
alias g='git'
alias ga='git add'
alias gaa='git add -A .'
alias gap='git add -p'
alias gbr='git branch'
alias gch='git checkout'
alias gcb='git checkout -b'
alias gc='git commit'
alias gca='git commit -a'
alias gcm='git commit -m'
alias gcam='git commit -am'
alias gco='git commit --amend --no-edit'
alias gd='git diff'
alias gds='git diff --staged'
alias gf='git fetch -p'
alias gl='git log --pretty=format:"%Cred%h%Creset - %s%C(yellow)%d%Creset" --graph --abbrev-commit -n 15 --branches'
alias gm='git merge'
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
  local dir
  dir="$(ghq root)/$(ghq list | fzf-tmux --reverse)" && cd $dir
}

bindkey -r '^G'

fzf-git-nocommit-file() {
  local selected
  selected=($(git status -s | fzf-tmux -m --ansi --preview "git diff --color \$(echo {} | awk '{ print \$2 }')" | awk '{ print $2 }'))
  LBUFFER="${LBUFFER}${selected}"
}
zle -N fzf-git-nocommit-file
bindkey '^G^T' fzf-git-nocommit-file

fzf-git-log() {
  local selected
  selected=($(git log --pretty=format:'%C(yellow)%h%C(reset) %s %C(green)%an%C(reset)' | fzf-tmux --ansi --preview "git diff --color \$(echo {} | awk '{ print \$1 \"^ \" \$1 }')" | awk '{ print $1 }'))
  LBUFFER="${LBUFFER}${selected}"
}
zle -N fzf-git-log
bindkey '^G^L' fzf-git-log

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
  touch README.md
}
