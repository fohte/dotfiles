return {
  'andymass/vim-matchup',
  commit = '347c890d51ae8e63239e92c935d2297c94975538', -- renovate: branch=master
  event = 'VimEnter',
  config = function()
    vim.g.matchup_matchparen_offscreen = { method = 'popup' }
  end,
}
