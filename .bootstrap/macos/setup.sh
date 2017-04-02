#!/bin/bash

set -e

has() {
  which "$1" > /dev/null 2>&1
  return $?
}

setup_homebrew() {
  if ! has brew; then
    ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
  fi
  brew update
  brew upgrade
  brew tap Homebrew/bundle # Install Homebrew Bundle
  brew install mas # Install a CLI tool for the Mac App Store
  brew bundle # Install tools from Brewfile
}

echo "Setupping Homebrew..."
setup_homebrew
