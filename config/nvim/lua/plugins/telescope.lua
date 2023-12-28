return {
  'nvim-telescope/telescope.nvim',
  dependencies = {
    'nvim-lua/plenary.nvim',
    { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
  },
  keys = {
    {
      '<Leader>ep',
      function()
        require('telescope.builtin').find_files({ hidden = true })
      end,
      mode = 'n',
    },
    {
      '<Leader>e.',
      function()
        require('telescope.builtin').find_files({ hidden = true, search_dirs = { vim.fn.expand('%:h') } })
      end,
      mode = 'n',
    },
    {
      '<Leader>eg',
      function()
        require('telescope.builtin').live_grep()
      end,
      mode = 'n',
    },
    {
      '<Leader>eb',
      function()
        require('telescope.builtin').buffers()
      end,
      mode = 'n',
    },
  },
  config = function()
    require('telescope').setup({
      defaults = {
        vimgrep_arguments = {
          'rg',
          '--color=never',
          '--no-heading',
          '--with-filename',
          '--line-number',
          '--column',
          '--smart-case',
          '--hidden',
        },
      },
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
