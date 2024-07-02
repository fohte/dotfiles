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
          'pylsp',
          'pyright',
          'solargraph',
          'tailwindcss',
          'terraformls',
          'tsserver',
          'yamlls',
        }),
        {
          ['tailwindcss'] = function()
            require('lspconfig').tailwindcss.setup({
              on_attach = on_attach,
              filetypes = {
                'javascript.jsx',
                'typescript.tsx',
              },
              init_options = {
                userLanguages = {
                  ['javascript.jsx'] = 'javascriptreact',
                  ['typescript.tsx'] = 'typescriptreact',
                },
              },
            })
          end,
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
            local l_eslint_d = require('efmls-configs.linters.eslint_d')
            local l_shellcheck = require('efmls-configs.linters.shellcheck')
            local l_textlint = require('efmls-configs.linters.textlint')
            local l_actionlint = require('efmls-configs.linters.actionlint')

            -- formatters
            local f_eslint_d = require('efmls-configs.formatters.eslint_d')
            local f_prettier = require('efmls-configs.formatters.prettier_d')
            local f_shfmt = require('efmls-configs.formatters.shfmt')
            local f_stylua = require('efmls-configs.formatters.stylua')
            local f_terraform = require('efmls-configs.formatters.terraform_fmt')
            local f_ruff = require('efmls-configs.formatters.ruff')

            -- workaround for flat config
            -- https://github.com/mantoni/eslint_d.js/pull/282
            l_eslint_d.lintCommand = string.format('%s %s', 'env ESLINT_USE_FLAT_CONFIG=true', l_eslint_d.lintCommand)
            f_eslint_d.formatCommand =
              string.format('%s %s', 'env ESLINT_USE_FLAT_CONFIG=true', f_eslint_d.formatCommand)

            local languages = {
              ['bash'] = { l_shellcheck, f_shfmt },
              ['hcl'] = { f_terraform },
              ['javascript'] = { l_eslint_d, f_eslint_d, f_prettier },
              ['javascript.jsx'] = { l_eslint_d, f_eslint_d, f_prettier },
              ['json'] = { f_prettier },
              ['json5'] = { f_prettier },
              ['jsonc'] = { f_prettier },
              ['lua'] = { f_stylua },
              ['markdown'] = { l_textlint },
              ['python'] = { f_ruff },
              ['sh'] = { l_shellcheck, f_shfmt },
              ['typescript'] = { l_eslint_d, f_eslint_d, f_prettier },
              ['typescript.tsx'] = { l_eslint_d, f_eslint_d, f_prettier },
              ['yaml'] = { f_prettier },
              ['yaml.actions'] = { l_actionlint },
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
