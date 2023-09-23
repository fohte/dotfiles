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

        handlers = {
          function(server_name)
            require('lspconfig')[server_name].setup({})
          end,

          ['lua_ls'] = function()
            require('lspconfig').lua_ls.setup({
              settings = {
                Lua = {
                  diagnostics = {
                    globals = { 'vim' },
                  },
                },
              },
            })
          end,
        },
      })
    end,
  },
  {
    'neovim/nvim-lspconfig',
  },
}
