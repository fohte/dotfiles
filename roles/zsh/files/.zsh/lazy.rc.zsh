rbenv() {
  unfunction "$0"
  eval "$(rbenv init - --no-rehash)"
  $0 "$@"
}

pyenv() {
  unfunction "$0"
  eval "$(pyenv init - --no-rehash)"
  $0 "$@"
}

nodenv() {
  unfunction "$0"
  eval "$(nodenv init - --no-rehash)"
  $0 "$@"
}
