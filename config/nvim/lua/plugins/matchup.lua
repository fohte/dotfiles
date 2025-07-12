return {
  'andymass/vim-matchup',
  commit = 'c478d4a72bbf397eff42743198f1939f6a264736', -- renovate: branch=master
  event = 'VimEnter',
  config = function()
    vim.g.matchup_matchparen_offscreen = { method = 'popup' }
  end,
}
