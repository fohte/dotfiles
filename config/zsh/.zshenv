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

# Calculate checksum of zsh config files
calculate_zsh_config_checksum() {
  local debug_mode=false

  # Parse arguments
  if [[ "$1" == "--debug" ]]; then
    debug_mode=true
  fi

  local files=$(find -L "$ZSH_CONFIG_HOME" -type f \( -name "*.zsh" -o -name ".zshenv" -o -name ".zshrc" \) -o -path "*/rc/functions/*" -type f \
    ! -name ".zsh_history" \
    ! -name ".zsh_sessions" \
    ! -path "*/.zsh_sessions/*" 2>/dev/null)

  if $debug_mode; then
    echo "$files" >&2
  fi

  echo "$files" | xargs cat 2>/dev/null | shasum -a 256 | cut -d' ' -f1
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
  /usr/local/bin(N-/)
  /usr/bin(N-/)
  /bin(N-/)
  /usr/sbin(N-/)
  /sbin(N-/)
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

export BAT_THEME=1337

import_env 'homebrew.zsh'

import_env 'go.zsh'
import_env 'node.zsh'
import_env 'python.zsh'
import_env 'rust.zsh'
import_env 'terraform.zsh'
import_env 'vim.zsh'

# priotize packages installed with mise
import_env 'mise.zsh'

# fzf is installed by mise, so fzf.zsh must be loaded after mise.zsh
import_env 'fzf.zsh'

# direnv hook must be loaded after homebrew.zsh because direnv is installed by homebrew
has 'direnv' && eval "$(direnv hook zsh)"

# Calculate initial checksum of zsh config files
export ZSH_CONFIG_CHECKSUM=$(calculate_zsh_config_checksum)

# prioritize user's local bin directories
path=(
  $HOME/bin(N-/)
  $HOME/.local/bin(N-/)
  $path
)

[ -f ~/.local/.zshenv ] && source ~/.local/.zshenv
