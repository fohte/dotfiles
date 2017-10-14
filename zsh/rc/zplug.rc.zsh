source ~/.zplug/init.zsh

zplug 'zsh-users/zsh-completions'
zplug 'zsh-users/zsh-autosuggestions'
zplug 'zsh-users/zsh-syntax-highlighting', defer:2
zplug 'b4b4r07/enhancd', use:init.sh
zplug 'mafredri/zsh-async', from:github
zplug 'sindresorhus/pure', use:pure.zsh, from:github, as:theme

if ! zplug check --verbose; then
  printf 'Install? [y/N]: '
  if read -q; then
    echo; zplug install
  fi
fi

zplug load
