return {
  'RRethy/vim-illuminate',
  commit = '0d1e93684da00ab7c057410fecfc24f434698898',
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
