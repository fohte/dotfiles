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
}
