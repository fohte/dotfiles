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
}
