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
  pencil: {
    command: '/Applications/Pencil.app/Contents/Resources/app.asar.unpacked/out/mcp-server-darwin-arm64',
    args: ['--app', 'desktop'],
    env: {},
  },
  tq: {
    // Personal task management app (github.com/fohte/tq). /api/mcp is carved
    // out behind a dedicated Cloudflare Access application authorized by a
    // service token, bypassing the GitHub IdP login required for the rest of
    // the host.
    type: 'http',
    url: 'https://tq.fohte.net/api/mcp',
    // op item: "tq MCP (Cloudflare Access Service Token)"
    headersHelper: "CF_ACCESS_CLIENT_ID='op://Personal/pamhi2ise6e5xuqeeilflxf27a/username' CF_ACCESS_CLIENT_SECRET='op://Personal/pamhi2ise6e5xuqeeilflxf27a/credential' op-run-cached mcp-headers-from-env 'CF-Access-Client-Id=CF_ACCESS_CLIENT_ID' 'CF-Access-Client-Secret=CF_ACCESS_CLIENT_SECRET'",
  },
}
