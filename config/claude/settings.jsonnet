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
      'Edit(~/.cache/gh-issue-agent/**)',
      'Read(//tmp/**)',
      'Read(//var/folders/**/T/**)',
      'Read(~/.cache/gh-issue-agent/**)',
      'Read(~/.claude/**)',
      'Read(~/.local/share/nvim/lazy)',
      'Read(~/Dropbox)',
      'Read(~/Library/Application Support/CleanShot)',
      'Read(~/Library/CloudStorage/Dropbox)',
      'Read(~/ghq/**)',
      'Skill',
      'WebFetch',
      'WebSearch',
      'mcp__context7',
      'mcp__qmd',
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
  model: 'opus',
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
        matcher: 'Bash',
        hooks: [
          { type: 'command', command: 'runok check --format claude-code-hook' },
        ],
      },
      {
        hooks: [
          { type: 'command', command: 'a cc hook pre-tool-use' },
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
    'criticalthink@criticalthink': true,
    'rust-analyzer-lsp@claude-plugins-official': true,
    'gopls-lsp@claude-plugins-official': true,
    'frontend-design@claude-plugins-official': true,
  },
  alwaysThinkingEnabled: false,
  promptSuggestionEnabled: false,
  teammateMode: 'tmux',
}
