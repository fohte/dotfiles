add_path "$HOME"/.npm-global/bin(N-/)
add_path "$HOME"/.bun/bin(N-/)

# ni configuration
export NI_DEFAULT_AGENT="bun"

# Point npm/pnpm at a dotfiles-managed global config so `npm login` can keep
# writing the token to ~/.npmrc (user config) without leaking it into the repo.
export NPM_CONFIG_GLOBALCONFIG="$HOME/.config/npm/npmrc"

# Vitest defaults maxWorkers to core-count-minus-one; in browser mode each
# worker spawns its own headless Chromium process (~500MB RSS), so an
# unbounded worker count can pin every core and make the machine unusable.
# Vitest applies this env var directly, so it does not affect CI parallelism,
# which some projects set separately based on `process.env.CI`.
export VITEST_MAX_WORKERS=4
