has() {
  which "$1" > /dev/null 2>&1
  return $?
}

is_macos() {
  [[ $OSTYPE == darwin* ]]
}

is_tmux_running() {
  [ ! -z "$TMUX" ]
}

is_ssh_running() {
  [ ! -z "$SSH_CONNECTION" ] || [ ! -z "$SSH_CLIENT" ]
}
