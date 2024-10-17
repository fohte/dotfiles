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
                languages = { 'markdown', 'review' },
                linters = { 'textlint' },
                formatters = { 'textlint' },
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
