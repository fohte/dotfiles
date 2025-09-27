return {
  'andymass/vim-matchup',
  commit = 'b23ba393ee600f4f637999f2c02b06a17838e2f0', -- renovate: branch=master
  event = 'VimEnter',
  config = function()
    vim.g.matchup_matchparen_offscreen = { method = 'popup' }
  end,
}
