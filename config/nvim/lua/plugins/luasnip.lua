return {
  {
    'L3MON4D3/LuaSnip',
    version = 'v2.3.0',
    -- install jsregexp (optional!).
    build = 'make install_jsregexp',
    config = function()
      require('luasnip.loaders.from_snipmate').lazy_load()
    end,
    keys = {
      {
        '<C-e>',
        function()
          require('luasnip').expand()
        end,
        mode = { 'i' },
        silent = true,
      },
      {
        '<C-j>',
        function()
          require('luasnip').jump(1)
        end,
        mode = { 'i', 's' },
        silent = false,
      },
      {
        '<C-k>',
        function()
          require('luasnip').jump(-1)
        end,
        mode = { 'i', 's' },
        silent = false,
      },
    },
  },
}
