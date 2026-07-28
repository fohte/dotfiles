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

      // Langfuse MCP, see mcp-servers.private.jsonnet
      // https://mcp.reference.langfuse.com/
      // Tool naming is consistently RESTful: read tools are prefixed
      // get/list/query, writes are prefixed create/update/upsert/delete/
      // submit/add.
      'mcp__langfuse__get*',
      'mcp__langfuse__list*',
      'mcp__langfuse__query*',

      // Sentry MCP, see mcp-servers.private.jsonnet
      // https://mcp.sentry.dev/
      // Read tools are prefixed find/get/search. update_issue (write),
      // execute_sentry_tool (dynamic dispatcher that can invoke any catalog
      // tool, including writes, by name), and analyze_issue_with_seer
      // (triggers Seer AI analysis) don't match and stay gated.
      'mcp__sentry__find*',
      'mcp__sentry__get*',
      'mcp__sentry__search*',
    ],
  },
}
