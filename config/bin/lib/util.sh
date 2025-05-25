#!/bin/bash

has() {
  which "$1" > /dev/null 2>&1
  return $?
}

is_macos() {
  [[ $OSTYPE == darwin* ]]
}

is_linux() {
  [[ $OSTYPE == linux* ]]
}

is_tmux_running() {
  [ -n "$TMUX" ]
}

is_ssh_running() {
  [ -n "$SSH_CONNECTION" ] || [ -n "$SSH_CLIENT" ]
}
