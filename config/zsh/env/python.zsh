export PYENV_PATH="$HOME/.pyenv"

if [ -d "$PYENV_PATH" ]; then
  add_path \
    "$PYENV_PATH"/bin(N-/) \
    "$PYENV_PATH"/shims(N-/)
fi

if has rye; then
  source "$HOME/.rye/env"
fi
