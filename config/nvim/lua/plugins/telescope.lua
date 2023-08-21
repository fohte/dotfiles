return {
  'nvim-telescope/telescope.nvim',
  dependencies = { 'nvim-lua/plenary.nvim' },
  keys = {
    { '<Leader>ep', '<cmd>Telescope find_files<cr>', mode = 'n' },
    { '<Leader>ef', '<cmd>Telescope find_files<cr>', mode = 'n' },
    { '<Leader>e.', "<cmd>lua require('telescope.builtin').find_files({ search_dirs = {vim.fn.expand('%:h')} })<cr>", mode = 'n' },
    { '<Leader>eg', '<cmd>Telescope live_grep<cr>', mode = 'n'  },
    { '<Leader>eb', '<cmd>Telescope buffers<cr>', mode = 'n'  },
  },
}
