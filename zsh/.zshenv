# Resolve not intended PATH on Mac OS (El Capitan or newer)
# (en) https://mattprice.me/2015/zsh-path-issues-osx-el-capitan/
# (ja) http://qiita.com/t-takaai/items/8574ff312f2caa5177c2
setopt no_global_rcs

typeset -U path PATH fpath FPATH

path=( \
  $HOME/.local/bin(N-/) \
  $HOME/bin(N-/) \
  $HOME/.nodebrew/current/bin(N-/) \
  $HOME/.cabal/bin(N-/) \
  $HOME/.rbenv/bin(N-/) \
  $HOME/.pyenv/bin(N-/) \
  $GOPATH/bin(N-/) \
  $path \
)

fpath=( \
  /usr/local/share/zsh/site-functions(N-/) \
  $fpath
)

export GOPATH=$HOME/.go

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
export HISTSIZE=1000
export SAVEHIST=100000

# For vi mode in zsh
export KEYTIMEOUT=1

export FZF_CTRL_T_COMMAND='ag --hidden -g ""'
export FZF_DEFAULT_OPTS='--cycle'

# gpg-agent
export GPG_TTY=$(tty)

[ -f ~/.local/.zshenv ] && source ~/.local/.zshenv
