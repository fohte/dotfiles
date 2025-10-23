alias c='cat'
alias cp='cp -i'

alias l='ls -l'
has eza && alias ls='eza -aF' || alias ls='ls -ACFG'

if is_linux; then
  alias pbcopy='xsel --clipboard --input'
  alias pbpaste='xsel --clipboard --output'
fi

alias p='pbpaste'

alias rm='rm -I'
alias x='chmod +x'

has 'gsed' && alias sed='gsed'
has 'gawk' && alias awk='gawk'

alias ....='cd ../../..'
alias ...='cd ../..'
alias ..='cd ..'
alias /='cd $(git-root)'
alias //='cd $(git-root -r)'
alias u='cd -'
alias ~='cd ~'
alias q=exit

has assh && alias ssh="assh wrapper ssh --"

alias t='tig'

alias g'$'='git cmd-commit'
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
alias gl='git log'
alias gm='git merge'
alias gms='git merge --ff --squash'
alias gnb='git new-branch'
alias gnw='git new-worktree'
alias gp='git push -u'
alias gpl='git pull'
alias gr='git reset'
alias grb='git rebase'
alias grbc='git rebase --continue'
alias grbi='git rebase -i'
alias gre='git restore'
alias gres='git restore --staged'
alias grh='git reset --hard'
alias grs='git reset --soft'
alias gs='git status'
alias gsc='git with-stash commit'
alias gscm='git with-stash commit -m'
alias gsco='git with-stash commit --amend --no-edit'
alias gsm='git switch $(git main) && git pull'
alias gsp='git stash pop'
alias gss='git stash save'
alias gw='git worktree'

alias ghr='gh repo view --web'
alias ghprv='gh pr view --web' # [gh] [p]ull [r]equest [v]iew
alias ghprc='gh pr create --web' # [gh] [p]ull [r]equest [c]reate

has 'nvim' && alias vim='nvim'

alias v='vim'

alias b='bundle'
alias be='bundle exec'

alias d='docker'
alias dc='docker-compose'
alias dce='docker-compose exec'
alias dcr='docker-compose run'
alias dcrm='docker-compose run --rm'
alias dm='docker-machine'
alias dr='docker run'
alias drm='docker run --rm'
alias drmit='docker run --rm -it'

has aws-vault && alias ave='aws-vault exec'

alias ya='yarn add'
alias yr='yarn run'

alias tf='terraform'

alias reload='exec $SHELL -l'

alias -g F='| fzf --multi'
alias -g G='| grep'
alias -g GV='| grep -v'
alias -g J='| jq'
alias -g L='| less'
alias -g M='| more'
alias -g N='> /dev/null 2>&1'
alias -g S='| sed'
alias -g X='| xargs -I%'
alias -g XP='X -P "$(ncpu)"'
alias -g Y='| pbcopy'
alias -g TY='| tee >(pbcopy)'

alias -g intsall='install'

alias -s py=python
alias -s rb=ruby

mkcd() {
  mkdir -p $@ && cd $@;
}

ghqcd() {
  if [ -n "$1" ]; then
    cd "$(ghq list -e -p "$1")"
  else
    local dir
    dir="$(ghq list -p | sed "s/^${HOME//\//\\/}/~/g" | fzf)" && cd "$(eval echo "$dir")"
  fi
}

# ghq get & cd
ghqg() {
  ghq get "$1" && ghqcd "$1"
}

gocd() {
  local dir
  dir="$(echo $GOPATH/src/*/*/* | perl -pe 's/ /\n/g' | fzf)" && cd $dir
}

# cd to some plugin direcotries
# usage: plugcd <plugin-name>
plugcd() {
  local dirs

  case "$1" in
    lazy)
      dirs="$(find "${XDG_DATA_HOME:-$HOME/.local/share}/nvim/lazy" -mindepth 1 -maxdepth 1 -type d)"
      ;;
    *)
      cat << EOF
error: unknown plugin name $1
valid plugin names:
  lazy
EOF
      return 1
      ;;
  esac

  dir="$(echo $dirs | fzf)" && cd "$dir"
}

# usage: gh-review <pr-url>
gh-review() {
  pr_url="$1"

  # https://github.com/foo/bar/pull/123 -> github.com/foo/bar
  repo="$(echo "$pr_url" | cut -d/ -f3-5)"
  repo_dir="$(ghq root)/$repo"
  if [ ! -d "$repo_dir" ]; then
    ghq get "$repo"
    echo "[gh-review] cloned $repo"
  fi
  cd "$repo_dir"
  echo "[gh-review] cd to $repo_dir"

  pr_number="$(echo "$pr_url" | sed -E 's|.*pull/([0-9]+).*|\1|')"
  gh pr checkout "$pr_number"
  echo "[gh-review] checkout #$pr_number"
}

if [ -z "$CLAUDECODE" ] ; then # use normal gh command on Claude Code to avoid frequent authentication
  [ -f "$HOME/.config/op/plugins.sh" ] && source "$HOME/.config/op/plugins.sh"
fi
