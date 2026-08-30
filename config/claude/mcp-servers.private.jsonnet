// op:// refs will be resolved by the op-run-cached wrapper
{
  grafana: {
    // https://github.com/grafana/mcp-grafana
    type: 'stdio',
    command: 'op-run-cached',
    args: ['uvx', 'mcp-grafana'],
    env: {
      GRAFANA_URL: 'https://fohte.grafana.net',
      // Grafana Service Account Token
      GRAFANA_SERVICE_ACCOUNT_TOKEN: 'op://Personal/v4frcwhkmpcg27dlf3jdc7psvi/credential',
    },
  },
  langfuse: {
    // https://langfuse.com/docs/api-and-data-platform/features/mcp-server
    // Basic auth needs two keys combined, which no single op:// ref can express,
    // so mcp-headers-from-env assembles the header instead.
    type: 'http',
    url: 'https://jp.cloud.langfuse.com/api/public/mcp',
    // op item: "Langfuse API Key (ローカル用)"
    headersHelper: "LANGFUSE_PUBLIC_KEY='op://Personal/tshqhuwmpvzyr5lkozvqesb4nu/public key' LANGFUSE_SECRET_KEY='op://Personal/tshqhuwmpvzyr5lkozvqesb4nu/secret key' op-run-cached mcp-headers-from-env 'Authorization=basic:LANGFUSE_PUBLIC_KEY:LANGFUSE_SECRET_KEY'",
  },
  sentry: {
    // https://mcp.sentry.dev/ — OAuth, no token to manage: Claude Code opens a
    // browser to sign in on first connection and caches the resulting credentials.
    type: 'http',
    url: 'https://mcp.sentry.dev/mcp',
  },
  't-rader': {
    // Cloudflare Access requires a service token; the token's two halves live
    // in separate op fields, so mcp-headers-from-env assembles the header.
    type: 'http',
    url: 'https://t-rader.fohte.net/mcp/mgmt',
    // op item: "t-rader MCP (Cloudflare Access Service Token)"
    headersHelper: "CF_ACCESS_CLIENT_ID='op://Personal/pamhi2ise6e5xuqeeilflxf27a/username' CF_ACCESS_CLIENT_SECRET='op://Personal/pamhi2ise6e5xuqeeilflxf27a/credential' op-run-cached mcp-headers-from-env 'CF-Access-Client-Id=CF_ACCESS_CLIENT_ID' 'CF-Access-Client-Secret=CF_ACCESS_CLIENT_SECRET'",
  },
}
