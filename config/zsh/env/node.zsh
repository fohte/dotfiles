add_path "$HOME"/.npm-global/bin(N-/)
add_path "$HOME"/.bun/bin(N-/)

# ni configuration
export NI_DEFAULT_AGENT="bun"

# Point npm/pnpm at a dotfiles-managed global config so `npm login` can keep
# writing the token to ~/.npmrc (user config) without leaking it into the repo.
export NPM_CONFIG_GLOBALCONFIG="$HOME/.config/npm/npmrc"

# vitest reads a different env var for the worker cap depending on major
# version (WORKERS from 4.0; THREADS/FORKS pools before that).
if [[ -z "$CI" ]]; then
  export VITEST_MAX_WORKERS=4
  export VITEST_MAX_THREADS=4
  export VITEST_MAX_FORKS=4
fi
