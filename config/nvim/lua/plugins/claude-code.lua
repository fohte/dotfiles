return {
  'coder/claudecode.nvim',
  commit = '2e6ea6f2a63cdf4fd3c05e6a054151d46848d319', -- renovate: branch=main
  dependencies = { 'folke/snacks.nvim', commit = '5e0e8698526f350f1280ad1ef7a8670f857c9445' }, -- renovate: branch=main
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
