local on_attach = function(client, buffer)
  -- Disable formatting for lua_ls (use stylua via EFM instead)
  if client.name == 'lua_ls' then
    client.server_capabilities.documentFormattingProvider = false
    client.server_capabilities.documentRangeFormattingProvider = false
  end

  local augroup = vim.api.nvim_create_augroup('LspFormatting', { clear = false })
  if client.supports_method('textDocument/formatting') then
    vim.api.nvim_clear_autocmds({ group = augroup, buffer = buffer })
    vim.api.nvim_create_autocmd('BufWritePre', {
      group = augroup,
      buffer = buffer,
      callback = function()
        vim.lsp.buf.format()
      end,
    })
  end
end

-- Get capabilities with blink.cmp integration
local function get_capabilities()
  local ok, blink = pcall(require, 'blink.cmp')
  if ok then
    return blink.get_lsp_capabilities()
  else
    return vim.lsp.protocol.make_client_capabilities()
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
      -- List of servers to ensure are installed
      local ensure_installed = {
        'bashls',
        'copilot',
        'cssls',
        'efm',
        'emmet_language_server',
        'gopls',
        'jqls',
        'jsonls',
        'lua_ls',
        'marksman',
        'mdx_analyzer',
        'pylsp',
        'pyright',
        'rust_analyzer',
        'solargraph',
        'steep',
        'tailwindcss',
        'terraformls',
        'ts_ls',
        'yamlls',
      }

      -- For mason-lspconfig v2.0.0+, we need to disable automatic_enable
      -- and manually configure servers
      require('mason-lspconfig').setup({
        ensure_installed = ensure_installed,
        automatic_enable = false, -- Disable automatic enabling to use our custom configs
      })

      -- Base configuration for all servers
      local base_config = {
        on_attach = on_attach,
        capabilities = get_capabilities(),
      }

      -- Helper function to setup server with config
      local function setup_server(server_name, config)
        vim.lsp.config(server_name, vim.tbl_deep_extend('force', base_config, config or {}))
        vim.lsp.enable(server_name)
      end

      -- Manually set up servers with custom configurations
      local handlers = {
        -- Default handler for servers without custom configuration
        function(server_name)
          setup_server(server_name)
        end,

        -- Custom handlers for specific servers
        ['tailwindcss'] = function()
          setup_server('tailwindcss', {
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
          setup_server('lua_ls', {
            settings = {
              Lua = {
                diagnostics = {
                  globals = { 'vim', 'hs' },
                },
                -- use stylua
                format = {
                  enable = false,
                },
              },
            },
          })
        end,

        ['copilot'] = function()
          -- Do nothing - copilot-lsp plugin will handle copilot_ls server
        end,

        ['rust_analyzer'] = function()
          setup_server('rust_analyzer', {
            on_attach = function(client, buffer)
              on_attach(client, buffer)

              -- Enable inlay hints
              vim.lsp.inlay_hint.enable(true, { bufnr = buffer })
            end,

            settings = {
              ['rust-analyzer'] = {
                check = {
                  command = 'clippy',
                },
                inlayHints = {
                  typeHints = {
                    enable = true,
                  },
                  chainingHints = {
                    enable = true,
                  },
                  parameterHints = {
                    enable = true,
                  },
                },
              },
            },
          })
        end,

        ['efm'] = function()
          local efm_configs = require('user.lsp.efm')

          efm_configs.setup({
            {
              languages = { 'javascript', 'typescript', 'typescript.tsx' },
              linters = { 'eslint' },
              formatters = { 'eslint', 'prettier' },
            },
            {
              languages = { 'lua' },
              formatters = { 'stylua' },
            },
            {
              languages = { 'yaml' },
              formatters = { 'prettier' },
            },
            {
              languages = { 'json', 'json5', 'jsonc' },
              formatters = { 'prettier' },
            },
            {
              languages = { 'jsonnet' },
              formatters = { 'jsonnet' },
            },
            {
              languages = { 'markdown', 'review' },
              linters = { 'textlint' },
              -- The textlint formatter may not be reflected & 2 blank lines may be added to the end of the file, so it is temporarily disabled
              -- formatters = { 'textlint' },
            },
            {
              languages = { 'sh', 'bash' },
              linters = { 'shellcheck' },
              formatters = { 'shfmt' },
            },
            {
              languages = { 'hcl' },
              formatters = { 'terraform' },
            },
            {
              languages = { 'yaml.actions' },
              linters = { 'actionlint' },
            },
            {
              languages = { 'go' },
              linters = { 'golangci-lint' },
              formatters = { 'goimports' },
            },
            {
              languages = { 'python' },
              formatters = { 'ruff' },
            },
          })

          vim.lsp.config('efm', {
            filetypes = efm_configs.filetypes,
            settings = {
              rootMarkers = { '.git/' },
              languages = efm_configs.languages,
            },
            init_options = {
              documentFormatting = true,
              documentRangeFormatting = true,
            },
            on_attach = on_attach,
            capabilities = get_capabilities(),
          })
          vim.lsp.enable('efm')
        end,
      }

      -- Set up each server
      for _, server in ipairs(ensure_installed) do
        if handlers[server] then
          handlers[server]()
        else
          handlers[1](server) -- Use default handler
        end
      end
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
          vim.lsp.buf.hover({ border = 'rounded' })
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
      vim.lsp.config('rubocop', { on_attach = on_attach })
      vim.lsp.enable('rubocop')
    end,
  },
  {
    'creativenull/efmls-configs-nvim',
    dependencies = { 'neovim/nvim-lspconfig' },
  },
  {
    'https://git.sr.ht/~whynothugo/lsp_lines.nvim',
    config = function()
      require('lsp_lines').setup()

      -- Disable virtual_text since it's redundant due to lsp_lines.
      vim.diagnostic.config({
        virtual_text = false,
      })

      vim.keymap.set('n', '<Leader>ll', require('lsp_lines').toggle, { desc = 'Toggle lsp_lines' })
    end,
  },
  {
    'aznhe21/actions-preview.nvim',
    config = function()
      vim.keymap.set({ 'v', 'n' }, 'ga', require('actions-preview').code_actions)
    end,
  },
}
