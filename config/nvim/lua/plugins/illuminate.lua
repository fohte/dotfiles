return {
  'RRethy/vim-illuminate',
  event = { 'BufReadPost', 'BufNewFile' },
  -- Ensure treesitter is loaded first; illuminate's treesitter provider calls
  -- tree:range() and errors out if nvim-treesitter hasn't attached yet.
  dependencies = { 'nvim-treesitter/nvim-treesitter' },
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
