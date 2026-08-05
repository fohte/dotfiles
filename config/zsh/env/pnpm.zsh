if is_macos; then
  export PNPM_HOME="$HOME/Library/pnpm"
else
  export PNPM_HOME="$HOME/.local/share/pnpm"
fi

# Appended (not add_path, which prepends) so a same-named wrapper in
# config/bin (e.g. `tq`, earlier on PATH via ~/bin) takes priority over
# pnpm's own global bin, avoiding recursion into the wrapper.
#
# pnpm v11+ nests global bins under bin/; earlier versions link directly into
# PNPM_HOME. Keep both on PATH.
path=($path "$PNPM_HOME"(N-/) "$PNPM_HOME"/bin(N-/))
