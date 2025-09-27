return {
  'nvim-telescope/telescope.nvim',
  commit = 'b4da76be54691e854d3e0e02c36b0245f945c2c7', -- renovate: branch=master
  dependencies = {
    { 'nvim-lua/plenary.nvim', commit = 'b9fd5226c2f76c951fc8ed5923d85e4de065e509' }, -- renovate: branch=master
    { 'nvim-telescope/telescope-fzf-native.nvim', commit = '1f08ed60cafc8f6168b72b80be2b2ea149813e55', build = 'make' }, -- renovate: branch=main
    { 'fdschmidt93/telescope-egrepify.nvim', commit = '5e6fb91f52a595a0dd554c7eea022c467ff80d86' }, -- renovate: branch=master
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
        require('telescope').extensions.egrepify.egrepify({})
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
        mappings = {
          i = {
            ['<C-s>'] = 'select_horizontal',
          },
        },
      },
      pickers = {
        find_files = {
          -- sort by modified
          find_command = { 'rg', '--files', '--hidden', '--sortr=modified' },
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
    require('telescope').load_extension('egrepify')
  end,
}
