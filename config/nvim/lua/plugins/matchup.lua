return {
  'andymass/vim-matchup',
  version = 'v0.7.3',
  event = 'VimEnter',
  config = function()
    vim.g.matchup_matchparen_offscreen = { method = 'popup' }
  end,
}
