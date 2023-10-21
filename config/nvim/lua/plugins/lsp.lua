local on_attach = function(client, buffer)
  local augroup = vim.api.nvim_create_augroup('LspFormatting', { clear = false })
  if client.supports_method('textDocument/formatting') then
    vim.api.nvim_create_autocmd('BufWritePre', {
      vim.api.nvim_clear_autocmds({ group = augroup, buffer = buffer }),
      group = augroup,
      buffer = buffer,
      callback = function()
        vim.lsp.buf.format()
      end,
    })
  end
end

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
          ['lua_ls'] = function()
            require('lspconfig').lua_ls.setup({
              settings = {
                Lua = {
                  diagnostics = {
                    globals = { 'vim', 'hs' },
                  },
                },
              },

              on_attach = on_attach,
            })
          end,

          ['efm'] = function()
            -- linters
            local l_eslint = require('efmls-configs.linters.eslint')
            local l_shellcheck = require('efmls-configs.linters.shellcheck')
            local l_textlint = require('efmls-configs.linters.textlint')

            -- formatters
            local f_prettier = require('efmls-configs.formatters.prettier_d')
            local f_shfmt = require('efmls-configs.formatters.shfmt')
            local f_stylua = require('efmls-configs.formatters.stylua')

            local languages = {
              bash = { l_shellcheck, f_shfmt },
              json = { f_prettier },
              lua = { f_stylua },
              markdown = { l_textlint },
              sh = { l_shellcheck, f_shfmt },
              typescript = { l_eslint, f_prettier },
              yaml = { f_prettier },
            }

            local efmls_config = {
              filetypes = vim.tbl_keys(languages),
              settings = {
                rootMarkers = { '.git/' },
                languages = languages,
              },
              init_options = {
                documentFormatting = true,
                documentRangeFormatting = true,
              },
            }

            require('lspconfig').efm.setup(vim.tbl_extend('force', efmls_config, {
              on_attach = on_attach,
            }))
          end,
        },
      })
    end,
  },
  {
    'neovim/nvim-lspconfig',
    keys = {
      {
        '<F10>',
        function()
          vim.lsp.buf.format()
        end,
      },
      {
        'gd',
        function()
          vim.lsp.buf.definition()
        end,
      },
      {
        'gy',
        function()
          vim.lsp.buf.type_definition()
        end,
      },
      {
        'gi',
        function()
          vim.lsp.buf.implementation()
        end,
      },
      {
        'gr',
        function()
          vim.lsp.buf.references()
        end,
      },
      {
        'K',
        function()
          vim.lsp.buf.hover()
        end,
      },
      {
        '<F9>',
        function()
          vim.lsp.buf.rename()
        end,
      },
    },
    config = function()
      local lspconfig = require('lspconfig')

      require('lspconfig').rubocop.setup({ on_attach = on_attach })
    end,
  },
  {
    'creativenull/efmls-configs-nvim',
    version = 'v1.x.x', -- version is optional, but recommended
    dependencies = { 'neovim/nvim-lspconfig' },
  },
}
