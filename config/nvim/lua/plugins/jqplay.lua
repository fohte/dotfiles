return {
  'phelipetls/vim-jqplay',
  cmd = { 'Jqplay', 'JqplayClose', 'JqplayScratch' },
  config = function()
    vim.g.jqplay = { mods = 'vertical' }
  end,
}
