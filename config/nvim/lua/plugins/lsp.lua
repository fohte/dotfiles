return {
  {
    'williamboman/mason.nvim',
    config = function()
      require('mason').setup()
    end,
  },
  {
    'williamboman/mason-lspconfig.nvim',
    dependencies = {
      { 'williamboman/mason.nvim' },
      { 'neovim/nvim-lspconfig' },
    },
    config = function()
      require('mason-lspconfig').setup({
        ensure_installed = {
          'lua_ls',
          'bashls',
          'cssls',
          'efm',
          'gopls',
          'emmet_language_server',
          'jsonls',
          'tsserver',
          'jqls',
          'mdx_analyzer',
          'pyright',
          'solargraph',
          'yamlls',
        },
      })
    end,
  },
  {
    'neovim/nvim-lspconfig',
  },
}
