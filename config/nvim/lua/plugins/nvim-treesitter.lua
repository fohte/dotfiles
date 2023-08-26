return {
  'nvim-treesitter/nvim-treesitter',
  build = ':TSUpdate',
  event = { 'BufReadPost', 'BufNewFile' },
  config = function()
    require('nvim-treesitter.configs').setup({
      ensure_installed = {
        'javascript',
        'json',
        'json5',
        'lua',
        'tsx',
        'typescript',
        'vim',
      },
      highlight = {
        enable = true,
        disable = {},
      },
    })
  end,
}
