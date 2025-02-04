return {
  'RRethy/vim-illuminate',
  -- renovate: datasource=github-releases depName=RRethy/vim-illuminate
  commit = '5eeb7951fc630682c322e88a9bbdae5c224ff0aa',
  config = function()
    require('illuminate').configure({
      providers = {
        'lsp',
        'treesitter',
        'regex',
      },
      delay = 0,
    })
  end,
}
