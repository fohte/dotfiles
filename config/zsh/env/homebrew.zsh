# for Linuxbrew (Homebrew on Linux)
if [ -d "$HOME/.linuxbrew" ]; then
  eval "$("$HOME/.linuxbrew/bin/brew" shellenv)"
fi

# for Homebrew (macOS)
if [ -f /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

! has brew && return 0

brew_prefix="$(brew --prefix)"

fpath=(
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
