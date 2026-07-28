{
  permissions+: {
    allow+: [
      // Slack MCP (claude.ai connector)
      // read-only
      'mcp__claude_ai_Slack__slack_read_canvas',
      'mcp__claude_ai_Slack__slack_read_channel',
      'mcp__claude_ai_Slack__slack_read_thread',
      'mcp__claude_ai_Slack__slack_read_user_profile',
      'mcp__claude_ai_Slack__slack_search_channels',
      'mcp__claude_ai_Slack__slack_search_public',
      'mcp__claude_ai_Slack__slack_search_public_and_private',
      'mcp__claude_ai_Slack__slack_search_users',

      // Grafana MCP, see mcp-servers.private.jsonnet
      // https://github.com/grafana/mcp-grafana
      // Service account is Viewer role, so write operations are blocked at the
      // Grafana API level regardless of MCP tool permissions.
      'mcp__grafana',
    ],
  },
}
