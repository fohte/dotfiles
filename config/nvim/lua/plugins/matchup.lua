return {
  'andymass/vim-matchup',
  commit = 'b4efd6a97380b99bb9f5eb80c9002e061402c288', -- renovate: branch=master
  event = 'VimEnter',
  config = function()
    vim.g.matchup_matchparen_offscreen = { method = 'popup' }
  end,
}
