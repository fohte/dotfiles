. ~/bin/lib/util.sh

export ZSH_CONFIG_HOME="$HOME/.config/zsh"
export ZSHRC_ROOT="$ZSH_CONFIG_HOME/rc"

source "$ZSH_CONFIG_HOME/lib/cache.zsh"

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

# Cheap change-detection fingerprint for zsh config files. Returns the
# mtime of the most recently modified tracked file; auto_reload_on_config_change
# compares this between startup and each precmd, so using mtime (not a full
# content hash) keeps the per-prompt cost under 2ms.
calculate_zsh_config_checksum() {
  emulate -L zsh
  # glob_dots is required to match .zshenv / .zshrc (dot-prefixed files).
  setopt extended_glob null_glob glob_dots
  zmodload -F zsh/stat b:zstat

  # `om[1]` = sort by mtime desc, take the first (= newest). Pure zsh glob
  # — no subshell, no external commands.
  local -a latest
  latest=("$ZSH_CONFIG_HOME"/**/*.(zsh|zshenv|zshrc)(.om[1]))

  if (( ${#latest} == 0 )); then
    echo 0
    return
  fi

  local mtime
  zstat -A mtime +mtime -- "${latest[1]}"
  echo "$mtime"
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
  $HOME/.local/bin(N-/)
  $HOME/bin(N-/)
  $HOME/.cabal/bin(N-/)
  /usr/local/bin(N-/)
  /usr/bin(N-/)
  /bin(N-/)
  /usr/sbin(N-/)
  /sbin(N-/)
  $path
)

export DOTPATH="$(dot path)"

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

import_env 'gcloud.zsh'
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

# Calculate initial checksum of zsh config files
export ZSH_CONFIG_CHECKSUM=$(calculate_zsh_config_checksum)

# Role-specific overlay (private: in-repo, work: external repo). The symlink
# is pre-resolved by `dot deploy` to avoid shelling out to `dot role` here.
[ -f "$ZSH_CONFIG_HOME/.zshenv.overlay" ] && source "$ZSH_CONFIG_HOME/.zshenv.overlay"

[ -f ~/.local/.zshenv ] && source ~/.local/.zshenv
