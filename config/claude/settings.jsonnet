local env(name) = std.extVar(name);

{
  env: {
    CLAUDE_CODE_DISABLE_FEEDBACK_SURVEY: '1',
    CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS: '1',
  },

  includeCoAuthoredBy: true,

  permissions: {
    allow: [
      'Bash(runok exec:*)',

      'Edit(//tmp/**)',
      'Edit(//var/folders/**/T/**)',
      'Edit(~/.cache/armyknife/**)',

      // Obsidian vault: both symlink (~/Dropbox) and resolved (~/Library/CloudStorage/Dropbox)
      // paths are required. Claude Code checks both depending on context.
      // Also, the path must be NFC-normalized (done in Makefile via iconv) because
      // macOS returns NFD paths but Claude Code normalizes file_path to NFC internally,
      // while permission patterns are NOT normalized, causing a mismatch.
      'Edit(' + env('OBSIDIAN_VAULT_PATH') + '/**)',
      'Edit(' + std.strReplace(env('OBSIDIAN_VAULT_PATH'), '~/Dropbox', '~/Library/CloudStorage/Dropbox') + '/**)',

      'Read(//tmp/**)',
      'Read(//var/folders/**/T/**)',
      'Read(~/.cache/armyknife/**)',
      'Read(~/.cargo/registry)',
      'Read(~/.claude/**)',
      'Read(~/.config/**)',
      'Read(~/.local/share/nvim/lazy)',
      'Read(~/Dropbox)',
      'Read(~/Library/Application Support/CleanShot)',
      'Read(~/Library/Application Support/gogcli)',
      'Read(~/Library/CloudStorage/Dropbox)',
      'Read(~/ghq/**)',

      'Skill',
      'WebFetch',
      'WebSearch',

      // Chrome DevTools MCP
      // read-only
      'mcp__chrome-devtools__get_console_message',
      'mcp__chrome-devtools__get_network_request',
      'mcp__chrome-devtools__list_console_messages',
      'mcp__chrome-devtools__list_network_requests',
      'mcp__chrome-devtools__list_pages',
      'mcp__chrome-devtools__take_screenshot',
      'mcp__chrome-devtools__take_snapshot',
      // page control (relatively safe)
      'mcp__chrome-devtools__close_page',
      'mcp__chrome-devtools__emulate',
      'mcp__chrome-devtools__navigate_page',
      'mcp__chrome-devtools__new_page',
      'mcp__chrome-devtools__resize_page',
      'mcp__chrome-devtools__select_page',
      'mcp__chrome-devtools__wait_for',

      // Google Analytics MCP
      'mcp__google-analytics',

      // Google Search Console MCP
      // read-only
      'mcp__gsc__list_sites',
      'mcp__gsc__search_analytics',
      'mcp__gsc__enhanced_search_analytics',
      'mcp__gsc__detect_quick_wins',
      'mcp__gsc__list_sitemaps',
      'mcp__gsc__get_sitemap',
      'mcp__gsc__index_inspect',

      // Grafana MCP (used by the `grafana` subagent)
      // https://github.com/grafana/mcp-grafana
      // Allowed: read-only operations, dashboard/annotation writes (recoverable),
      // and Sift investigation kicks (no production side effects).
      // NOT allowed (left to per-call confirmation): create_incident,
      // add_activity_to_incident, alerting_manage_rules, alerting_manage_routing.
      // admin (read)
      'mcp__grafana__list_teams',
      'mcp__grafana__list_users_by_org',
      'mcp__grafana__list_all_roles',
      'mcp__grafana__get_role_details',
      'mcp__grafana__get_role_assignments',
      'mcp__grafana__list_user_roles',
      'mcp__grafana__list_team_roles',
      'mcp__grafana__get_resource_permissions',
      'mcp__grafana__get_resource_description',
      // search / dashboards
      'mcp__grafana__search_dashboards',
      'mcp__grafana__get_dashboard_by_uid',
      'mcp__grafana__get_dashboard_panel_queries',
      'mcp__grafana__get_dashboard_property',
      'mcp__grafana__get_dashboard_summary',
      'mcp__grafana__run_panel_query',
      'mcp__grafana__update_dashboard',
      'mcp__grafana__patch_dashboard',
      // datasources (read)
      'mcp__grafana__list_datasources',
      'mcp__grafana__get_datasource',
      'mcp__grafana__get_query_examples',
      // prometheus
      'mcp__grafana__query_prometheus',
      'mcp__grafana__query_prometheus_histogram',
      'mcp__grafana__list_prometheus_metric_metadata',
      'mcp__grafana__list_prometheus_metric_names',
      'mcp__grafana__list_prometheus_label_names',
      'mcp__grafana__list_prometheus_label_values',
      // loki
      'mcp__grafana__query_loki_logs',
      'mcp__grafana__query_loki_stats',
      'mcp__grafana__query_loki_patterns',
      'mcp__grafana__list_loki_label_names',
      'mcp__grafana__list_loki_label_values',
      // clickhouse
      'mcp__grafana__list_clickhouse_tables',
      'mcp__grafana__describe_clickhouse_table',
      'mcp__grafana__query_clickhouse',
      // cloudwatch
      'mcp__grafana__list_cloudwatch_namespaces',
      'mcp__grafana__list_cloudwatch_metrics',
      'mcp__grafana__list_cloudwatch_dimensions',
      'mcp__grafana__query_cloudwatch',
      // elasticsearch
      'mcp__grafana__query_elasticsearch',
      // logs (search)
      'mcp__grafana__search_logs',
      // incident (read)
      'mcp__grafana__list_incidents',
      'mcp__grafana__get_incident',
      // sift (read + safe writes that just kick off an investigation job)
      'mcp__grafana__list_sift_investigations',
      'mcp__grafana__get_sift_investigation',
      'mcp__grafana__get_sift_analysis',
      'mcp__grafana__find_error_pattern_logs',
      'mcp__grafana__find_slow_requests',
      // oncall (read)
      'mcp__grafana__list_oncall_schedules',
      'mcp__grafana__get_oncall_shift',
      'mcp__grafana__get_current_oncall_users',
      'mcp__grafana__list_oncall_teams',
      'mcp__grafana__list_oncall_users',
      'mcp__grafana__list_alert_groups',
      'mcp__grafana__get_alert_group',
      // pyroscope
      'mcp__grafana__list_pyroscope_label_names',
      'mcp__grafana__list_pyroscope_label_values',
      'mcp__grafana__list_pyroscope_profile_types',
      'mcp__grafana__fetch_pyroscope_profile',
      // asserts
      'mcp__grafana__get_assertions',
      // navigation
      'mcp__grafana__generate_deeplink',
      // annotations
      'mcp__grafana__get_annotations',
      'mcp__grafana__get_annotation_tags',
      'mcp__grafana__create_annotation',
      'mcp__grafana__update_annotation',
      'mcp__grafana__patch_annotation',
      // rendering
      'mcp__grafana__get_panel_image',

      'mcp__context7',
      'mcp__qmd',
      'mcp__pencil',
    ],
    deny: [
      'NotebookEdit',
      'Read(.env)',
      'Read(.env.local)',
      'Read(.envrc)',
      'mcp__qmd__query',
      'mcp__qmd__vsearch',
    ],
    defaultMode: 'acceptEdits',
  },

  hooks: {
    SessionStart: [
      {
        hooks: [
          { type: 'command', command: 'a cc hook session-start' },
          { type: 'command', command: 'gen-claude-template context' },
        ],
      },
    ],
    UserPromptSubmit: [
      {
        hooks: [
          { type: 'command', command: 'a cc hook user-prompt-submit' },
        ],
      },
    ],
    PreToolUse: [
      {
        // Combined into a single hook to work around Claude Code #15897:
        // updatedInput is silently dropped when multiple hooks match the same tool.
        hooks: [
          { type: 'command', command: '~/.claude/hooks/pre-tool-use.bash' },
        ],
      },
    ],
    PostToolUse: [
      {
        hooks: [
          { type: 'command', command: 'a cc hook post-tool-use' },
        ],
      },
    ],
    Notification: [
      {
        hooks: [
          { type: 'command', command: 'a cc hook notification' },
        ],
      },
    ],
    PermissionRequest: [
      {
        hooks: [
          { type: 'command', command: 'a cc hook permission-request' },
        ],
      },
    ],
    Stop: [
      {
        hooks: [
          { type: 'command', command: 'a cc hook stop' },
        ],
      },
    ],
    SessionEnd: [
      {
        hooks: [
          { type: 'command', command: 'a cc hook session-end' },
        ],
      },
    ],
  },
  statusLine: {
    type: 'command',
    command: '~/.claude/statusline.ts',
  },
  enabledPlugins: {
    'frontend-design@claude-plugins-official': true,
    'gopls-lsp@claude-plugins-official': true,
    'runok@runok-claude-code-plugin': true,
    'rust-analyzer-lsp@claude-plugins-official': true,
    'skill-creator@claude-plugins-official': true,
  },
  extraKnownMarketplaces: {
    'runok-claude-code-plugin': {
      source: {
        repo: 'fohte/runok-claude-code-plugin',
        source: 'github',
      },
      autoUpdate: true,
    },
  },
  alwaysThinkingEnabled: false,
  promptSuggestionEnabled: false,
  teammateMode: 'tmux',

  // use skills and CLAUDE.md instead of memory
  autoMemoryEnabled: false,
  autoDreamEnabled: false,
}
