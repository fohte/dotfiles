. ~/bin/lib/util.sh

# Resolve not intended PATH on Mac OS (El Capitan or newer)
# (en) https://mattprice.me/2015/zsh-path-issues-osx-el-capitan/
# (ja) http://qiita.com/t-takaai/items/8574ff312f2caa5177c2
setopt no_global_rcs

export GOPATH=$HOME/.go

typeset -U path PATH fpath FPATH

path=( \
  $HOME/.nodebrew/current/bin(N-/) \
  $HOME/.cabal/bin(N-/) \
  $GOPATH/bin(N-/) \
  $HOME/.cargo/bin(N-/) \
  /usr/local/bin(N-/) \
  /usr/bin(N-/) \
  /bin(N-/) \
  /usr/sbin(N-/) \
  /sbin(N-/) \
  $path \
)

path=(
  $(yarn global bin)(N-/) \
  $path \
)

has 'rbenv' && eval "$(rbenv init - --no-rehash)"
has 'pyenv' && eval "$(pyenv init - --no-rehash)"
has 'direnv' && eval "$(direnv hook zsh)"

path=(
  $HOME/.local/bin(N-/) \
  $HOME/bin(N-/) \
  $path \
)

fpath=( \
  /usr/local/share/zsh/site-functions(N-/) \
  $fpath
)

export PYENV_ROOT=$(pyenv root)

export DOTPATH="$(dotpath)"

export LANG='en_US.UTF-8'
if [ type -a 'nvim' 2>&1 > /dev/null ]; then
  export EDITOR='nvim'
else
  export EDITOR='vim'
fi
export PAGER='less'

export WORDCHARS='*?_-.[]~=&;!#$%^(){}<>+'

export TIMEFMT=$'\nreal\t%E\nuser\t%U\nsys\t%S'

export HISTFILE=$HOME/.zsh_history
export HISTSIZE=10000
export SAVEHIST=100000

# For vi mode in zsh
export KEYTIMEOUT=1

export FZF_CTRL_T_COMMAND='ag --hidden -g ""'
export FZF_DEFAULT_OPTS='--cycle'

# gpg-agent
export GPG_TTY=$(tty)

export FZF_DEFAULT_OPTS='--bind ctrl-a:select-all,ctrl-d:deselect-all,ctrl-t:toggle-all'

[ -f ~/.local/.zshenv ] && source ~/.local/.zshenv
