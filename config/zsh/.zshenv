. ~/bin/lib/util.sh

export ZSH_CONFIG_HOME="$HOME/.config/zsh"
export ZSHRC_ROOT="$ZSH_CONFIG_HOME/rc"

import_zsh_config() {
  local source_file="$1"

  if [ -f "$source_file" ]; then
    source "$source_file"
  else
    echo "$source_file not found" >&2
    exit 1
  fi
}

import_env() {
  import_zsh_config "$ZSH_CONFIG_HOME/env/$1"
}

typeset -U path PATH fpath FPATH manpath MANPATH

add_path() {
  path=($@ $path)
}

# Resolve not intended PATH on Mac OS (El Capitan or newer)
# (en) https://mattprice.me/2015/zsh-path-issues-osx-el-capitan/
# (ja) http://qiita.com/t-takaai/items/8574ff312f2caa5177c2
setopt no_global_rcs

path=(
  $HOME/.cabal/bin(N-/)
  $HOME/.cargo/bin(N-/)
  /usr/local/bin(N-/)
  /usr/bin(N-/)
  /bin(N-/)
  /usr/sbin(N-/)
  /sbin(N-/)
  $HOME/.local/bin(N-/)
  $HOME/bin(N-/)
  $path
)

export DOTPATH="$(dotpath)"

# `-R`: display ANSI color escape sequences in "raw" form
# `-S`: disable line wrapping (Side-scroll to see long lines)
# `-X`: leave file contents on the screen when less exits
export LESS='-RSX'

export LANG='en_US.UTF-8'
export LC_ALL='en_US.UTF-8'
export PAGER='less'

export WORDCHARS='*?_-.[]~=&;!#$%^(){}<>+'

export TIMEFMT=$'\nreal\t%E\nuser\t%U\nsys\t%S'

export HISTFILE=$HOME/.zsh_history
export HISTSIZE=10000
export SAVEHIST=100000

# For vi mode in zsh
export KEYTIMEOUT=1

# gpg-agent
export GPG_TTY=$(tty)

# pre-commit
# ignore pre-commit error when no .pre-commit-config.yaml is found
export PRE_COMMIT_ALLOW_NO_CONFIG=1

import_env 'homebrew.zsh'

import_env 'fzf.zsh'
import_env 'go.zsh'
import_env 'node.zsh'
import_env 'python.zsh'
import_env 'ruby.zsh'
import_env 'terraform.zsh'
import_env 'vim.zsh'

# priotize packages installed with mise
import_env 'mise.zsh'

# direnv hook must be loaded after homebrew.zsh because direnv is installed by homebrew
has 'direnv' && eval "$(direnv hook zsh)"

[ -f ~/.local/.zshenv ] && source ~/.local/.zshenv
