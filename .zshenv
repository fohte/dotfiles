typeset -U path PATH fpath FPATH

path=( \
  $HOME/.nodebrew/current/bin(N-/) \
  $HOME/.cabal/bin(N-/) \
  $HOME/.rbenv/bin(N-/) \
  $HOME/.pyenv/shims(N-/) \
  $path \
)

fpath=( \
  /usr/local/share/zsh/site-functions(N-/) \
  $fpath
)

export GOPATH=$HOME/.go

export ZSHDIR=$HOME/.zsh

export LANG='en_US.UTF-8'
export EDITOR='vim'
export PAGER='less'

export WORDCHARS='*?_-.[]~=&;!#$%^(){}<>+'

export HISTFILE=$HOME/.zsh_history
export HISTSIZE=1000
export SAVEHIST=100000
