return {
  'andymass/vim-matchup',
  commit = '81313f17443df6974cafa094de52df32b860e1b7', -- renovate: branch=master
  event = 'VimEnter',
  config = function()
    vim.g.matchup_matchparen_offscreen = { method = 'popup' }
  end,
}
