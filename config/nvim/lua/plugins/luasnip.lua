return {
  {
    'L3MON4D3/LuaSnip',
    commit = '03c8e67eb7293c404845b3982db895d59c0d1538',
    -- install jsregexp (optional!).
    build = 'make install_jsregexp',
    config = function()
      require('luasnip.loaders.from_snipmate').lazy_load()
    end,
    keys = {
      {
        '<C-w>',
        mode = { 'i', 's' },
        function()
          if require('luasnip').expand_or_jumpable() then
            require('luasnip').expand_or_jump()
          end
        end,
      },
      {
        '<C-b>',
        mode = { 'i', 's' },
        function()
          if require('luasnip').jumpable(-1) then
            require('luasnip').jump(-1)
          end
        end,
      },
    },
  },
}
