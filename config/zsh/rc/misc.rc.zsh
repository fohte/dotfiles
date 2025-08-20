zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion:*:default' menu select=1
zstyle ':completion:*' completer _expand_alias _complete _ignored

setopt menu_complete

setopt ignore_eof
setopt rm_star_wait

# match dot files (hidden files) with glob
setopt glob_dots

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

# Auto-reload zsh configuration when files change
auto_reload_on_config_change() {
  # Calculate current checksum
  local current_checksum=$(calculate_zsh_config_checksum)

  # Auto-reload if checksum differs
  if [[ "$current_checksum" != "$ZSH_CONFIG_CHECKSUM" ]]; then
    # Show message on current line in dim yellow
    printf '\e[2;33m✨ zsh config changed, reloading shell...\e[0m\r'
    exec $SHELL -l
  fi
}

precmd_functions+=(auto_reload_on_config_change)

# Capture command for jqplay
jqplay_preexec() {
  if [[ "$1" == *"jqplay"* ]]; then
    export JQPLAY_FULL_CMD="$1"
  fi
}

add-zsh-hook preexec jqplay_preexec
