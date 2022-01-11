# for Linuxbrew (Homebrew on Linux)
if [ -d "$HOME/.linuxbrew" ]; then
  eval "$("$HOME/.linuxbrew/bin/brew" shellenv)"
fi

# for Homebrew (macOS)
if [ -f /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi
