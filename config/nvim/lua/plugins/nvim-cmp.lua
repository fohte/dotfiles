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
        snippet = {
          expand = function(args)
            if vim.fn.exists('*UltiSnips#Anon') == 1 then
              vim.fn['UltiSnips#Anon'](args.body) -- For `ultisnips` users.
            end
          end,
        },

        mapping = map.preset.insert({
          ['<C-b>'] = map.scroll_docs(-4),
          ['<C-f>'] = map.scroll_docs(4),
          ['<C-g>'] = map.abort(),
          ['<Tab>'] = map.confirm({ select = true }),
          ['<C-e>'] = map.complete(),
          ['<C-n>'] = map.select_next_item(),
          ['<C-p>'] = map.select_prev_item(),
        }),

        sources = cmp.config.sources(
          {
            { name = 'copilot' },
            { name = 'nvim_lsp' },
            { name = 'luasnip' },
            { name = 'path' },
            { name = 'git' },
          },

          -- if lsp is not available, use buffer
          {
            { name = 'buffer' },
          }
        ),

        experimental = {
          ghost_text = true,
        },

        sorting = {
          priority_weight = 2,
          comparators = {
            require('copilot_cmp.comparators').prioritize,

            -- Below is the default comparitor list and order for nvim-cmp
            cmp.config.compare.offset,
            -- cmp.config.compare.scopes, --this is commented in nvim-cmp too
            cmp.config.compare.exact,
            cmp.config.compare.score,
            cmp.config.compare.recently_used,
            cmp.config.compare.locality,
            cmp.config.compare.kind,
            cmp.config.compare.sort_text,
            cmp.config.compare.length,
            cmp.config.compare.order,
          },
        },

        formatting = {
          format = require('lspkind').cmp_format({
            mode = 'symbol',
            maxwidth = 50,
            ellipsis_char = '…',
            show_labelDetails = true,
            symbol_map = {
              Copilot = '',
            },
          }),
        },
      })

      cmp.setup.cmdline({ '/', '?' }, {
        mapping = cmp.mapping.preset.cmdline(),
        sources = {
          { name = 'buffer' },
        },
      })

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
      { 'hrsh7th/cmp-path', commit = 'c6635aae33a50d6010bf1aa756ac2398a2d54c32' },
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
