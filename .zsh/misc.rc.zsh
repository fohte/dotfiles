zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

do_enter() {
  if [[ -n "$BUFFER" ]]; then
    zle accept-line
    return 0
  fi

  echo
  ls

  if [ "$(git rev-parse --is-inside-work-tree 2> /dev/null)" = 'true' ]; then
    echo
    git status --short --branch
  fi

  zle reset-prompt
  return 0
}
zle -N do_enter
bindkey "^m" do_enter
