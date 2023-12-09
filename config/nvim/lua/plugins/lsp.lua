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
      local utils = require('utils')
      local function create_lsp_setup_function(server_name)
        return function()
          require('lspconfig')[server_name].setup({
            on_attach = on_attach,
          })
        end
      end

      local function create_handlers(server_names)
        local handlers = {}

        for _, server_name in ipairs(server_names) do
          handlers[server_name] = create_lsp_setup_function(server_name)
        end

        return handlers
      end

      local handlers = utils.mergeTables(
        create_handlers({
          'bashls',
          'cssls',
          'emmet_language_server',
          'gopls',
          'jqls',
          'jsonls',
          'mdx_analyzer',
          'pyright',
          'solargraph',
          'terraformls',
          'tsserver',
          'yamlls',
        }),
        {
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
              ['bash'] = { l_shellcheck, f_shfmt },
              ['json'] = { f_prettier },
              ['json5'] = { f_prettier },
              ['jsonc'] = { f_prettier },
              ['lua'] = { f_stylua },
              ['markdown'] = { l_textlint },
              ['sh'] = { l_shellcheck, f_shfmt },
              ['typescript'] = { l_eslint, f_prettier },
              ['typescript.tsx'] = { l_eslint, f_prettier },
              ['yaml'] = { f_prettier },
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
        }
      )

      require('mason-lspconfig').setup({
        ensure_installed = utils.get_keys_from_table(handlers),
        handlers = handlers,
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
