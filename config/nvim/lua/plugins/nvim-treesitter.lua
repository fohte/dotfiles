return {
  {
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    event = { 'BufReadPost', 'BufNewFile' },
    config = function()
      require('nvim-treesitter.configs').setup({
        ensure_installed = {
          'bash',
          'javascript',
          'json',
          'json5',
          'lua',
          'ruby',
          'tsx',
          'typescript',
          'vim',
        },
        highlight = {
          enable = true,
          disable = {},
        },
        endwise = {
          enable = true,
        },
      })
    end,
  },
  {
    'RRethy/nvim-treesitter-endwise',
  },
}
