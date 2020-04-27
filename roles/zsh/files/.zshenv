. ~/bin/lib/util.sh

export ZSHRC_ROOT="$HOME/.zsh"

# Resolve not intended PATH on Mac OS (El Capitan or newer)
# (en) https://mattprice.me/2015/zsh-path-issues-osx-el-capitan/
# (ja) http://qiita.com/t-takaai/items/8574ff312f2caa5177c2
setopt no_global_rcs

export GOPATH=$HOME/.go

typeset -U path PATH fpath FPATH

path=( \
  $HOME/.nodebrew/current/bin(N-/) \
  $HOME/.nodenv/bin(N-/) \
  $HOME/.nodenv/shims(N-/) \
  $HOME/.pyenv/bin(N-/) \
  $HOME/.pyenv/shims(N-/) \
  $HOME/.rbenv/bin(N-/) \
  $HOME/.rbenv/shims(N-/) \
  $HOME/.cabal/bin(N-/) \
  $GOPATH/bin(N-/) \
  $HOME/.cargo/bin(N-/) \
  $HOME/.npm-global/bin(N-/) \
  /usr/local/bin(N-/) \
  /usr/bin(N-/) \
  /bin(N-/) \
  /usr/sbin(N-/) \
  /sbin(N-/) \
  $path \
)

has 'direnv' && eval "$(direnv hook zsh)"

path=(
  $HOME/.local/bin(N-/) \
  $HOME/bin(N-/) \
  $path \
)

fpath=( \
  /usr/local/share/zsh/site-functions(N-/) \
  $HOME/.zsh/completions(N-/) \
  $fpath
)

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
has fd && export FZF_ALT_C_COMMAND='fd . -t d'
export FZF_DEFAULT_OPTS='--cycle --bind ctrl-a:select-all,ctrl-d:deselect-all,ctrl-t:toggle-all'

# gpg-agent
export GPG_TTY=$(tty)

# a cache directory for Terraform plugins
export TF_PLUGIN_CACHE_DIR=~/.cache/terraform/plugins

# increase parallelism form 10 from 20
export TF_CLI_ARGS_plan="-parallelism=20"
export TF_CLI_ARGS_apply="-parallelism=20"
export TF_CLI_ARGS_destroy="-parallelism=20"

[ -f ~/.local/.zshenv ] && source ~/.local/.zshenv
