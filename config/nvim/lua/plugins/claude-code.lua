return {
  'coder/claudecode.nvim',
  dependencies = { 'folke/snacks.nvim' },
  keys = {
    { '<M-,>', '<cmd>ClaudeCodeFocus<cr>', desc = 'Claude Code', mode = { 'n', 'x' } },
  },
  opts = {
    terminal = {
      snacks_win_opts = {
        position = 'float',
        width = 0.85,
        height = 0.85,
        border = 'rounded',
        keys = {
          claude_hide = {
            '<M-,>',
            function(self)
              self:hide()
            end,
            mode = 't',
            desc = 'Hide',
          },
        },
      },
    },
  },
  config = true,
}
