return {
  'coder/claudecode.nvim',
  commit = '3e2601f1ac0eb61231ee6c6a7f9e8be82420f371', -- renovate: branch=main
  dependencies = { 'folke/snacks.nvim', commit = 'bc0630e43be5699bb94dadc302c0d21615421d93' }, -- renovate: branch=main
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
