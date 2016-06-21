#!/bin/bash

if [ -z "${DOTPATH:-}" ]; then
  readonly DOTPATH="${HOME}/dotfiles"
fi

if [ -z "${DOTFILES_GITHUB:-}" ]; then
  readonly DOTFILES_GITHUB="https://github.com/Fohte/dotfiles"
fi

readonly HEADER='
    .___      __    _____.__.__
  __| _/_____/  |__/ ____\__|  |   ____   ______
 / __ |/  _ \   __\   __\|  |  | _/ __ \ /  ___/
/ /_/ (  <_> )  |  |  |  |  |  |_\  ___/ \___ \
\____ |\____/|__|  |__|  |__|____/\___  >____  >
     \/                               \/     \/    @Fohte
'

readonly HOW_TO_INSTALL="
Installation
  1. Change directory to ${DOTPATH}
        $ cd ${DOTPATH}
  2. Symlinking dotfiles to your home directory using make
        $ make deploy
"

has() {
  which "$1" > /dev/null 2>&1
  return $?
}

log_fail() {
  echo "$1" 1>&2
}

if [ -d "${DOTPATH}" ]; then
  log_fail "${DOTPATH}: already exists"
  exit 1
fi

echo "${HEADER}"
echo "Downloading ${DOTFILES_GITHUB}.git into ${DOTPATH} ..."

if has "git"; then
  git clone --recursive "${DOTFILES_GITHUB}" "${DOTPATH}"

elif has "curl" || has "wget"; then
  tarball="${DOTFILES_GITHUB}/archive/master.tar.gz"

  if has "curl"; then
    curl -L "${tarball}"

  elif has "wget"; then
    wget -O - "${tarball}"

  fi | tar xvz

  command mv -f dotfiles-master "${DOTPATH}"

else
  log_fail "curl or wget required"
  exit 1

fi

command cd "${DOTPATH}"

if [ $? = 0 ]; then
  echo "Successfully downloaded dotfiles in ${DOTPATH}"
  echo "${HOW_TO_INSTALL}"
  exit 0

else
  log_fail "Failed to download dotfiles in ${DOTPATH}"
  exit 1

fi
