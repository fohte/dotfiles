# complete aliased commands (e.g., aws aliased to `op plugin run -- aws`)
setopt completealiases

# bash-style completions
autoload -U +X bashcompinit && bashcompinit
complete -C "$(which aws_completer)" aws

# armyknife (a command)
() {
  local a_bin
  a_bin="$(command -v a)" || return
  cache_source a-completions "$a_bin" -- "$a_bin" completions zsh
}
