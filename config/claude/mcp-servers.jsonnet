local env(name) = std.extVar(name);

{
  context7: {
    type: 'stdio',
    // op:// refs will be resolved by the op-run-cached wrapper
    command: 'op-run-cached',
    args: ['npx', '-y', '@upstash/context7-mcp'],
    env: {
      // Context7 API Key
      CONTEXT7_API_KEY: 'op://Personal/vzna62vsddi7jiv4dmhum3y7f4/credential',
    },
  },
  qmd: {
    type: 'stdio',
    command: 'qmd',
    args: ['mcp'],
    env: {},
  },
  'codebase-memory': {
    type: 'stdio',
    // MCP clients exec `command` directly without shell expansion, so a literal
    // ~ would not resolve.
    command: env('HOME') + '/.claude/hooks/cbm-mcp-launcher.bash',
    args: [],
    env: {},
    // Exempt from tool-search deferral: a ToolSearch step would make Grep/Read
    // the cheaper path.
    alwaysLoad: true,
  },
  pencil: {
    command: '/Applications/Pencil.app/Contents/Resources/app.asar.unpacked/out/mcp-server-darwin-arm64',
    args: ['--app', 'desktop'],
    env: {},
  },
}
