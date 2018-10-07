#!/bin/bash

set -e

has() {
  which "$1" > /dev/null 2>&1
  return "$?"
}

red_echo() {
  echo -e "\e[31m$*\e[m"
}

green_echo() {
  echo -e "\e[32m$*\e[m"
}

yellow_echo() {
  echo -e "\e[33m$*\e[m"
}

raise_error() {
  red_echo "ERROR: $*"
  return 1
}

install_ansible() {
  case "$OSTYPE" in
    darwin*)
      if ! has brew; then
        raise_error 'brew command is not found. You should install Homebrew first.'
      fi

      brew install ansible
      ;;

    linux*)
      if ! has apt; then
        echo 'apt command is not found. Your environment is not supported yet.'
        return 1
      fi

      sudo apt update
      sudo apt install -y software-properties-common
      sudo add-apt-repository --yes --update ppa:ansible/ansible
      sudo apt install -y ansible
      ;;

    *)
      raise_error "Your platform ($OSTYPE) is not supported yet."
      ;;
  esac

  if has ansible-playbook; then
    green_echo 'ansible-playbook command is installed successfully!'
  else
    raise_error 'ansible-playbook command could not be installed.'
    return 1
  fi
}

if has ansible-playbook; then
  green_echo 'ansible-playbook command is already installed!'
else
  yellow_echo 'ansible-playbook command is not found. Installing Ansible...'
  install_ansible
fi
