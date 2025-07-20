export RYE_HOME="$HOME/.rye"

if [ -d "$RYE_HOME" ]; then
  add_path "$RYE_HOME"/shims(N-/)
fi
