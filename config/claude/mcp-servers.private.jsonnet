{
  grafana: {
    // https://github.com/grafana/mcp-grafana
    // GRAFANA_URL / GRAFANA_SERVICE_ACCOUNT_TOKEN must be exported in the
    // parent shell (e.g. via direnv or ~/.local/.zshenv) so the MCP server
    // picks them up at startup.
    type: 'stdio',
    command: 'uvx',
    args: ['mcp-grafana'],
    env: {},
  },
}
