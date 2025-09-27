return {
  'RRethy/vim-illuminate',
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
