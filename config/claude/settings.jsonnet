local env(name) = std.extVar(name);

{
  env: {
    CLAUDE_CODE_DISABLE_FEEDBACK_SURVEY: '1',
    ANTHROPIC_BASE_URL: 'http://127.0.0.1:8787',
  },

  // Parallel work is driven by separate tmux panes/sessions, not the
  // in-app agent-team feature, so the agent view panel is redundant.
  disableAgentView: true,

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
      'Read(~/.cache/runok/presets/**)',
      'Read(~/.cargo/registry)',
      'Read(~/.claude/**)',
      'Read(~/.go/pkg/mod/**)',
      'Read(~/.opensrc/**)',
      'Read(~/.config/**)',
      'Read(~/.local/share/nvim/lazy)',
      'Read(~/Dropbox)',
      'Read(~/Library/Application Support/CleanShot)',
      'Read(~/Library/Application Support/gogcli)',
      'Read(~/Library/Application Support/rtk/**)',
      'Read(~/Library/CloudStorage/Dropbox)',
      'Read(~/ghq/**)',

      'Skill',
      'WebFetch',
      'WebSearch',

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
      // Service account is Viewer role, so write operations are blocked at the
      // Grafana API level regardless of MCP tool permissions.
      'mcp__grafana',

      'mcp__context7',
      'mcp__qmd',
      'mcp__pencil',

      // Allow all codebase-memory-mcp tools — index/query/trace are read-only
      // against a local SQLite cache. Destructive operations are denied below.
      'mcp__codebase-memory',
    ],
    deny: [
      'NotebookEdit',
      'Read(.env)',
      'Read(.env.local)',
      'Read(.envrc)',

      // Fable is priced far above the other tiers and gets prohibitively
      // expensive once fanned out across subagents, so block explicit
      // model:"fable" requests here. The implicit-inherit path (no model
      // specified anywhere) is handled by the agent-guard hook instead,
      // since permission rules never match an omitted parameter.
      'Agent(model:fable)',

      'mcp__qmd__query',
      'mcp__qmd__vsearch',

      // Wipes the indexed project from the local SQLite cache. Reversible only
      // by re-indexing, but accidental drops cost minutes of rebuild time.
      'mcp__codebase-memory__delete_project',

      // Block self-scheduling tools. Claude sometimes defers the current task
      // by scheduling itself ("I'll check this again later") instead of doing
      // it now, or schedules a "follow-up check" a day out when the right
      // answer is to act immediately. Removing the tools forecloses that path.
      'ScheduleWakeup',
      'CronCreate',
      'CronDelete',
      'CronList',

      // Both are busy-wait polling, which is fragile and wastes time.
      // TaskOutput is additionally marked deprecated in its own tool
      // description in favor of waiting for <task-notification> and reading
      // the output file directly. The Agent tool's return value serves the
      // same purpose when waiting in the foreground.
      'Monitor',
      'TaskOutput',
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
      {
        // Reminds the agent to call codebase-memory-mcp tools before falling
        // back to grep/read. Fires on startup/resume/clear/compact so the hint
        // survives context clears and compaction.
        matcher: 'startup|resume|clear|compact',
        hooks: [
          { type: 'command', command: '~/.claude/hooks/cbm-session-reminder' },
        ],
      },
      {
        // Symlink role overlay skill directories (config-overlays/claude/skills/*)
        // into ~/.claude/skills/ flat, since Claude Code only discovers personal
        // skills at the top level.
        hooks: [
          { type: 'command', command: '~/.claude/hooks/link-overlay-skills' },
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
        // Keep exactly one PreToolUse entry. Claude Code #15897 silently
        // drops `updatedInput` when multiple entries match the same tool;
        // add new per-tool guards inside pre-tool-use-proxy.bash instead.
        hooks: [
          { type: 'command', command: '~/.claude/hooks/pre-tool-use-proxy.bash' },
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
  alwaysThinkingEnabled: true,
  showThinkingSummaries: true,
  tui: 'fullscreen',
  promptSuggestionEnabled: false,
  agentPushNotifEnabled: false,
  editorMode: 'vim',

  // use skills and CLAUDE.md instead of memory
  autoMemoryEnabled: false,
  autoDreamEnabled: false,

  // sonnet5 xhigh > opus4.8 medium https://www.anthropic.com/news/claude-sonnet-5
  model: 'claude-sonnet-5[1m]',
  effortLevel: 'xhigh',
}
