return {
  {
    'hrsh7th/nvim-cmp',
    commit = 'b5311ab3ed9c846b585c0c15b7559be131ec4be9',
    event = { 'InsertEnter' },
    config = function()
      local cmp = require('cmp')
      local map = cmp.mapping

      -- Tab Completion Configuration (Highly Recommended)
      -- from: https://github.com/zbirenbaum/copilot-cmp#tab-completion-configuration-highly-recommended
      local has_words_before = function()
        if vim.api.nvim_buf_get_option(0, 'buftype') == 'prompt' then
          return false
        end
        local line, col = unpack(vim.api.nvim_win_get_cursor(0))
        return col ~= 0 and vim.api.nvim_buf_get_text(0, line - 1, 0, line - 1, col, {})[1]:match('^%s*$') == nil
      end

      cmp.setup({
        mapping = map.preset.insert({
          ['<C-b>'] = map.scroll_docs(-4),
          ['<C-f>'] = map.scroll_docs(4),
          ['<C-Space>'] = map.complete(),
          ['<C-e>'] = map.abort(),
          ['<C-m>'] = map.confirm({ select = true }),
          ['<Tab>'] = vim.schedule_wrap(function(fallback)
            if cmp.visible() and has_words_before() then
              cmp.select_next_item({ behavior = cmp.SelectBehavior.Select })
            else
              fallback()
            end
          end),
        }),
        sources = cmp.config.sources({
          { name = 'copilot' },
          { name = 'nvim_lsp' },
          { name = 'luasnip' },
        }, {
          { name = 'buffer' },
          { name = 'git' },
        }),
        snippet = {
          expand = function(args)
            require('luasnip').lsp_expand(args.body)
          end,
        },
        formatting = {
          format = function(entry, vim_item)
            local has_lspkind, lspkind = pcall(require, 'lspkind')
            if has_lspkind then
              return lspkind.cmp_format({
                mode = 'symbol_text',
                symbol_map = { Copilot = '' },
              })(entry, vim_item)
            end
            return vim_item
          end,
        },
        experimental = {
          ghost_text = true,
        },
      })

      -- Git integration
      cmp.setup.filetype('gitcommit', {
        sources = cmp.config.sources({
          { name = 'git' },
        }, {
          { name = 'buffer' },
        }),
      })

      -- Use buffer source for `/` and `?` (if you enabled `native_menu`, this won't work anymore).
      cmp.setup.cmdline({ '/', '?' }, {
        mapping = cmp.mapping.preset.cmdline(),
        sources = {
          { name = 'buffer' },
        },
      })

      -- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
      cmp.setup.cmdline(':', {
        mapping = cmp.mapping.preset.cmdline(),
        sources = cmp.config.sources({
          { name = 'path' },
        }, {
          { name = 'cmdline' },
        }),
      })
    end,
    dependencies = {
      { 'hrsh7th/cmp-buffer', commit = 'b74fab3656eea9de20a9b8116afa3cfc4ec09657' },
      { 'hrsh7th/cmp-cmdline', commit = 'd126061b624e0af6c3a556428712dd4d4194ec6d' },
      { 'hrsh7th/cmp-nvim-lsp', commit = 'a8912b88ce488f411177fc8aed358b04dc246d7b' },
      { 'hrsh7th/cmp-path', commit = 'e52e640b7befd8113b3350f46e8cfcfe98fcf730' },
      {
        'petertriho/cmp-git',
        commit = 'b24309c386c9666c549a1abaedd4956541676d06',
        config = function()
          require('cmp_git').setup({
            github = {
              issues = {
                state = 'all',
              },
            },
          })
        end,
      },
      { 'onsails/lspkind.nvim', commit = 'd79a1c3299ad0ef94e255d045bed9fa26025dab6' },
      { 'saadparwaiz1/cmp_luasnip', commit = '98d9cb5c2c38532bd9bdb481067b20fea8f32e90' },
      {
        'zbirenbaum/copilot-cmp',
        commit = '15fc12af3d0109fa76b60b5cffa1373697e261d1',
        dependencies = {
          { 'zbirenbaum/copilot.lua', commit = '46f4b7d026cba9497159dcd3e6aa61a185cb1c48' },
        },
        config = function()
          require('copilot_cmp').setup({
            panel = { enabled = false },
          })
        end,
      },
    },
  },
}
