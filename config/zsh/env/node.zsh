# mise for Node.js version management
if has 'mise'; then
  eval "$(mise activate zsh)"
fi

export NODENV_PATH="$HOME/.nodenv"

if [ -d "$NODENV_PATH" ]; then
  add_path \
    "$NODENV_PATH"/bin(N-/) \
    "$NODENV_PATH"/shims(N-/)
fi

add_path "$HOME"/.npm-global/bin(N-/)
add_path "$HOME"/.bun/bin(N-/)

export VOLTA_HOME="$HOME/.volta"

if [ -d "$VOLTA_HOME" ]; then
  add_path "$VOLTA_HOME"/bin(N-/)
fi
