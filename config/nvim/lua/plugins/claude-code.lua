return {
  'coder/claudecode.nvim',
  commit = '985b4b117ea13ec85c92830ecac8f63543dd5ead', -- renovate: branch=main
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
