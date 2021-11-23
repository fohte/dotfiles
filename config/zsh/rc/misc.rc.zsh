zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion:*:default' menu select=1
zstyle ':completion:*' completer _expand_alias _complete _ignored

setopt menu_complete

setopt ignore_eof
setopt rm_star_wait

zle-line-init zle-keymap-select() {
  if [ ! "$TERM" = "xterm-256color" ]; then
    return
  fi

  case $KEYMAP in
    vicmd)
      echo -ne "\e[2 q" # block
      ;;
    main|viins)
      echo -ne "\e[6 q" # vertical bar
      ;;
  esac
}
zle -N zle-line-init
zle -N zle-keymap-select
