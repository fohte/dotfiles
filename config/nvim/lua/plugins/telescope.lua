return {
  'nvim-telescope/telescope.nvim',
  dependencies = {
    'nvim-lua/plenary.nvim',
    { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
  },
  keys = {
    { '<Leader>ep', '<cmd>Telescope find_files<cr>', mode = 'n' },
    { '<Leader>ef', '<cmd>Telescope find_files<cr>', mode = 'n' },
    {
      '<Leader>e.',
      "<cmd>lua require('telescope.builtin').find_files({ search_dirs = {vim.fn.expand('%:h')} })<cr>",
      mode = 'n',
    },
    { '<Leader>eg', '<cmd>Telescope live_grep<cr>', mode = 'n' },
    { '<Leader>eb', '<cmd>Telescope buffers<cr>', mode = 'n' },
  },
  config = function()
    require('telescope').setup({
      extensions = {
        fzf = {
          fuzzy = true,
          override_generic_sorter = true,
          override_file_sorter = true,
          case_mode = 'smart_case',
        },
      },
    })

    require('telescope').load_extension('fzf')
  end,
}
