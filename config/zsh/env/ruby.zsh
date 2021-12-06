export RBENV_PATH="$HOME/.rbenv"

if [ -d "$RBENV_PATH" ]; then
  add_path \
    "$RBENV_PATH"/bin(N-/) \
    "$RBENV_PATH"/shims(N-/)
fi
