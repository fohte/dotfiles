has() {
  which "$1" > /dev/null 2>&1
  return $?
}

is_osx() {
  [[ $OSTYPE == darwin* ]]
}
