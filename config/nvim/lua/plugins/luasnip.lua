return {
  {
    'L3MON4D3/LuaSnip',
    commit = 'b3104910bb5ebf40492aadffae18f2528fa757d9', -- renovate: branch=master
    -- install jsregexp (optional!).
    build = 'make install_jsregexp',
    config = function()
      require('luasnip.loaders.from_snipmate').lazy_load()
    end,
    keys = {
      {
        '<C-w>',
        function()
          require('luasnip').expand()
        end,
        mode = { 'i' },
        silent = true,
      },
      {
        '<Tab>',
        function()
          require('luasnip').jump(1)
        end,
        mode = { 'i', 's' },
        silent = false,
      },
      {
        '<S-Tab>',
        function()
          require('luasnip').jump(-1)
        end,
        mode = { 'i', 's' },
        silent = false,
      },
    },
  },
}
