local env(name) = std.extVar(name);

{
  context7: {
    type: 'stdio',
    command: 'npx',
    args: ['-y', '@upstash/context7-mcp'],
    env: {},
  },
  qmd: {
    type: 'stdio',
    command: 'qmd',
    args: ['mcp'],
    env: {},
  },
  pencil: {
    command: '/Applications/Pencil.app/Contents/Resources/app.asar.unpacked/out/mcp-server-darwin-arm64',
    args: ['--app', 'desktop'],
    env: {},
  },
  'chrome-devtools': {
    type: 'stdio',
    command: 'npx',
    args: ['-y', 'chrome-devtools-mcp@latest'],
    env: {},
  },
  'codebase-memory': {
    type: 'stdio',
    // Launched via wrapper that cd's to the main repo when inside a worktree —
    // the server keys its index by CWD, so a bare `codebase-memory-mcp` would
    // build a separate graph per worktree. MCP clients exec `command` directly
    // without shell expansion, so the path must be absolute.
    command: env('HOME') + '/.claude/hooks/cbm-mcp-launcher.bash',
    args: [],
    env: {},
  },
}
