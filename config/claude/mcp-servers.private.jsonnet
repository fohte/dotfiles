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
    // so a helper assembles the header instead.
    type: 'http',
    url: 'https://jp.cloud.langfuse.com/api/public/mcp',
    // op item: "Langfuse API Key (ローカル用)"
    headersHelper: "LANGFUSE_PUBLIC_KEY='op://Personal/tshqhuwmpvzyr5lkozvqesb4nu/public key' LANGFUSE_SECRET_KEY='op://Personal/tshqhuwmpvzyr5lkozvqesb4nu/secret key' op-run-cached langfuse-mcp-headers",
  },
  sentry: {
    // https://mcp.sentry.dev/ — OAuth, no token to manage: Claude Code opens a
    // browser to sign in on first connection and caches the resulting credentials.
    type: 'http',
    url: 'https://mcp.sentry.dev/mcp',
  },
}
