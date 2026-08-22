local env(name) = std.extVar(name);

{
  env: {
    CLAUDE_CODE_DISABLE_FEEDBACK_SURVEY: '1',

    // Subagents can spawn subagents of their own by default (up to three
    // layers below the main conversation), which sometimes runs away in an
    // unintended nested-spawn loop. Setting this to 1 withholds the Agent
    // tool from every subagent, so nesting is impossible.
    // https://code.claude.com/docs/en/sub-agents.md#let-subagents-spawn-their-own-subagents
    CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH: '1',

    // A fork inherits the parent's whole context, so it re-bills what
    // delegation is supposed to shed. Its availability also drops
    // `run_in_background` from the Agent tool schema, which makes every
    // subagent launch asynchronous with no way to opt out.
    CLAUDE_CODE_FORK_SUBAGENT: '0',
  },

  // Parallel work is driven by separate tmux panes/sessions, not the
  // in-app agent-team feature, so the agent view panel is redundant.
  disableAgentView: true,

  // Artifacts publish work product to claude.ai, which no local workflow here
  // depends on; crit preview covers viewing generated HTML locally. Disabling
  // rather than denying: a deny rule blocks the call but keeps the (large)
  // tool definition in every request.
  disableArtifact: true,

  // Fan-out is driven by the Agent tool and separate sessions. Gates only the
  // Workflow tool, /workflows, and the ultracode keyword; SendMessage and the
  // Agent tool are unaffected.
  disableWorkflows: true,

  includeCoAuthoredBy: true,

  // Bundled skills (dataviz, code-review, claude-api, etc.) are never used
  // here and cost context on every session. Disables every bundled skill
  // except /doctor. https://code.claude.com/docs/en/settings-reference.md
  disableBundledSkills: true,

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
      'Read(~/.local/share/mise/installs/**)',
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

      'mcp__context7',
      'mcp__qmd',
      'mcp__pencil',
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
        // Symlink role overlay skill directories (config-overlays/claude/skills/*)
        // into ~/.claude/skills/ flat, since Claude Code only discovers personal
        // skills at the top level.
        hooks: [
          { type: 'command', command: '~/.claude/hooks/link-overlay-skills' },
        ],
      },
      {
        // Reset context-split-threshold tracking after compaction rewrites
        // the transcript.
        matcher: 'compact',
        hooks: [
          { type: 'command', command: '~/.claude/hooks/context-split-guard.ts' },
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
      {
        // Notify Claude via additionalContext once context usage crosses each
        // threshold, so long sessions get proposed to split.
        hooks: [
          { type: 'command', command: '~/.claude/hooks/context-split-guard.ts' },
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
    'crit@crit': true,
    'frontend-design@claude-plugins-official': true,
    'gopls-lsp@claude-plugins-official': true,
    'ponytail@ponytail': true,
    'runok@runok-claude-code-plugin': true,
    'rust-analyzer-lsp@claude-plugins-official': true,
    'skill-creator@claude-plugins-official': true,
  },
  extraKnownMarketplaces: {
    crit: {
      source: {
        repo: 'tomasz-tomczyk/crit',
        source: 'github',
      },
      autoUpdate: true,
    },
    ponytail: {
      source: {
        repo: 'DietrichGebert/ponytail',
        source: 'github',
      },
      autoUpdate: true,
    },
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

  // Output quality degrades as context fills, long before the model's limit
  // (~967K for Sonnet 5), so compact earlier than the tuned window.
  autoCompactWindow: 300000,

  // sonnet5 xhigh > opus4.8 medium https://www.anthropic.com/news/claude-sonnet-5
  model: 'claude-sonnet-5[1m]',
  effortLevel: 'xhigh',
}
