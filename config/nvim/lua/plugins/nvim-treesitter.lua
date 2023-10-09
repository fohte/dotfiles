return {
  {
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    event = { 'BufReadPost', 'BufNewFile' },
    dependencies = {
      'RRethy/nvim-treesitter-endwise',
      'nvim-treesitter/nvim-treesitter-context',
    },
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
        highlight = { enable = true, disable = {} },
        endwise = { enable = true },
        context = { enable = true },
      })
    end,
  },
}
