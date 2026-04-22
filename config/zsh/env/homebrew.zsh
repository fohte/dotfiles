# Cache `brew shellenv` output to avoid spawning brew on every shell start.
# Invalidated when the brew binary is newer than the cache.
() {
  local brew_bin
  if [[ -f /opt/homebrew/bin/brew ]]; then
    brew_bin=/opt/homebrew/bin/brew
  elif [[ -x "$HOME/.linuxbrew/bin/brew" ]]; then
    brew_bin="$HOME/.linuxbrew/bin/brew"
  else
    return
  fi

  cache_source brew-shellenv "$brew_bin" -- "$brew_bin" shellenv
}

! has brew && return 0

# HOMEBREW_PREFIX is exported by `brew shellenv`; avoid spawning `brew --prefix`
brew_prefix="${HOMEBREW_PREFIX:-$(brew --prefix)}"

fpath=(
  "$ZSH_CONFIG_HOME"/rc/functions(N-/)
  "$brew_prefix"/share/zsh/site-functions(N-/)
  $fpath
)

path=(
  "$brew_prefix"/opt/coreutils/libexec/gnubin(N-/)
  "$brew_prefix"/opt/findutils/libexec/gnubin(N-/)
  "$brew_prefix"/opt/gnu-sed/libexec/gnubin(N-/)
  "$brew_prefix"/opt/gnu-tar/libexec/gnubin(N-/)
  "$brew_prefix"/opt/grep/libexec/gnubin(N-/)
  $path
)

manpath=(
  "$brew_prefix"/opt/coreutils/libexec/gnuman(N-/)
  "$brew_prefix"/opt/findutils/libexec/gnuman(N-/)
  "$brew_prefix"/opt/gnu-sed/libexec/gnuman(N-/)
  "$brew_prefix"/opt/gnu-tar/libexec/gnuman(N-/)
  "$brew_prefix"/opt/grep/libexec/gnuman(N-/)
  $manpath
)
