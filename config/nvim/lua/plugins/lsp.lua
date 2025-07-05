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
          'steep',
          'tailwindcss',
          'terraformls',
          'ts_ls',
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
                  -- use stylua
                  format = {
                    enable = false,
                  },
                },
              },

              on_attach = on_attach,
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

            require('lspconfig').efm.setup({
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
            })
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
    commit = '6bba673aa8993eceec233be17b42ddfb9540794b',
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

      vim.keymap.set('n', '<Leader>ll', require('lsp_lines').toggle, { desc = 'Toggle lsp_lines' })
    end,
  },
}
