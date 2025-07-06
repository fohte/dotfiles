local function on_attach(client, bufnr)
  if client.name == 'efm' then
    -- format with prettier on save
    vim.api.nvim_create_autocmd('BufWritePre', {
      pattern = { '*.js', '*.ts', '*.jsx', '*.tsx', '*.json', '*.md' },
      callback = function()
        vim.lsp.buf.format()
      end,
    })
  end
end

return {
  {
    'williamboman/mason.nvim',
    commit = '8024d64e1330b86044fed4c8494ef3dcd483a67c',
    config = function()
      require('mason').setup()
    end,
  },
  {
    'williamboman/mason-lspconfig.nvim',
    commit = 'c4c84f4521d62de595c0d0f718a9a40c1890c8ce',
    dependencies = {
      { 'williamboman/mason.nvim' },
      { 'neovim/nvim-lspconfig' },
    },
    config = function()
      local utils = require('utils')
      local function create_lsp_setup_function(server_name)
        return function()
          require('lspconfig')[server_name].setup({ on_attach = on_attach })
        end
      end

      local prettier_efm = require('efmls-configs.formatters.prettier')
      prettier_efm.env = {
        PRETTIERD_DEFAULT_CONFIG = (vim.loop.os_homedir() .. '/.config/prettier/.prettierrc.yml'),
      }

      local handlers = {
        create_lsp_setup_function,
        bashls = create_lsp_setup_function('bashls'),
        efm = function()
          local languages = {
            javascript = { prettier_efm },
            typescript = { prettier_efm },
            json = { prettier_efm },
            jsonc = { prettier_efm },
            json5 = { prettier_efm },
            markdown = { prettier_efm },
            ['markdown.mdx'] = { prettier_efm },
            yaml = { prettier_efm },
          }

          require('lspconfig').efm.setup({
            filetypes = vim.tbl_keys(languages),
            settings = {
              rootMarkers = { '.git/' },
              languages = languages,
            },
            init_options = {
              documentFormatting = true,
              documentRangeFormatting = true,
            },
            on_attach = on_attach,
          })
        end,
        emmet_language_server = function()
          require('lspconfig').emmet_language_server.setup({
            on_attach = on_attach,
            filetypes = { 'html', 'erb', 'eruby' },
          })
        end,
        eslint = function()
          require('lspconfig').eslint.setup({
            on_attach = function(client, bufnr)
              -- disable formatting capabilities provided by eslint lsp,
              -- because we will use prettier via efm instead
              client.server_capabilities.documentFormattingProvider = false
              client.server_capabilities.documentRangeFormattingProvider = false

              on_attach(client, bufnr)
            end,
          })
        end,
        jsonls = create_lsp_setup_function('jsonls'),
        lua_ls = function()
          require('lspconfig').lua_ls.setup({
            on_attach = on_attach,
            settings = {
              Lua = {
                runtime = {
                  version = 'LuaJIT',
                },
                diagnostics = {
                  globals = { 'vim' },
                },
                workspace = {
                  library = vim.api.nvim_get_runtime_file('', true),
                },
                telemetry = {
                  enable = false,
                },
              },
            },
          })
        end,
        nixd = function()
          require('lspconfig').nixd.setup({
            on_attach = on_attach,
            cmd = { 'nixd' },
            settings = {
              nixd = {
                nixpkgs = {
                  expr = 'import <nixpkgs> { }',
                },
                formatting = {
                  command = { 'nixpkgs-fmt' },
                },
                options = {
                  nixos = {
                    expr = '(builtins.getFlake ("git+file://" + toString ./.)).nixosConfigurations.k-on.options',
                  },
                  home_manager = {
                    expr = '(builtins.getFlake ("git+file://" + toString ./.)).homeConfigurations."heineken@k-on".options',
                  },
                },
              },
            },
          })
        end,
        pylsp = create_lsp_setup_function('pylsp'),
        pyright = create_lsp_setup_function('pyright'),
        rnix = create_lsp_setup_function('rnix'),
        ruby_lsp = function()
          require('lspconfig').ruby_lsp.setup({
            on_attach = on_attach,
            cmd = { vim.fn.expand('~/.rbenv/shims/ruby-lsp') },
          })
        end,
        rust_analyzer = create_lsp_setup_function('rust_analyzer'),
        sorbet = function()
          require('lspconfig').sorbet.setup({
            on_attach = on_attach,
            cmd = { 'bundle', 'exec', 'srb', 'tc', '--lsp' },
          })
        end,
        tailwindcss = create_lsp_setup_function('tailwindcss'),
        terraformls = create_lsp_setup_function('terraformls'),
        tflint = create_lsp_setup_function('tflint'),
        ['typescript-language-server'] = function()
          require('lspconfig').ts_ls.setup({ on_attach = on_attach })
        end,
        yamlls = create_lsp_setup_function('yamlls'),
      }

      require('mason-lspconfig').setup({
        ensure_installed = utils.get_keys_from_table(handlers),
        handlers = handlers,
      })
    end,
  },
  {
    'neovim/nvim-lspconfig',
    commit = '6bba673aa8993eceec233be17b42ddfb9540794b',
    keys = {
      {
        '<F10>',
        function()
          vim.lsp.buf.format()
        end,
      },
      {
        'K',
        function()
          vim.lsp.buf.hover()
        end,
      },
      {
        'gd',
        function()
          vim.lsp.buf.definition()
        end,
      },
      {
        'gD',
        function()
          vim.lsp.buf.declaration()
        end,
      },
      {
        'gi',
        function()
          vim.lsp.buf.implementation()
        end,
      },
      {
        'go',
        function()
          vim.lsp.buf.type_definition()
        end,
      },
      {
        'gr',
        function()
          vim.lsp.buf.references()
        end,
      },
      {
        'gs',
        function()
          vim.lsp.buf.signature_help()
        end,
      },
      {
        '<F2>',
        function()
          vim.lsp.buf.rename()
        end,
      },
      {
        '<F3>',
        function()
          vim.lsp.buf.code_action()
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
    commit = '8d7ede48afa7d0344fa62fefb95132c0dad41e97',
    dependencies = { 'neovim/nvim-lspconfig' },
  },
  {
    'https://git.sr.ht/~whynothugo/lsp_lines.nvim',
    commit = 'a92c755f182b89ea91bd8a6a2227208026f27b4d',
    config = function()
      require('lsp_lines').setup()

      -- Disable virtual_text since it's redundant due to lsp_lines.
      vim.diagnostic.config({
        virtual_text = false,
      })

      vim.keymap.set('', '<Leader>l', require('lsp_lines').toggle, { desc = 'Toggle lsp_lines' })
    end,
  },
}
