return {
  'andymass/vim-matchup',
  commit = '704c9d98e686836ae1c4b6c4ea5b057ecf5fbbca', -- renovate: branch=master
  event = 'VimEnter',
  config = function()
    vim.g.matchup_matchparen_offscreen = { method = 'popup' }
  end,
}
