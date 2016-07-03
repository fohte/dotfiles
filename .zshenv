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

export ZSHDIR="$HOME/.zsh"

export TERM=xterm-256color
export EDITOR='nvim'

export WORDCHARS='*?_-.[]~=&;!#$%^(){}<>+'

export HISTFILE=$HOME/.zsh_history
export HISTSIZE=1000
export SAVEHIST=100000
