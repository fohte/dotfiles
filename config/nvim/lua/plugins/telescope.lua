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
        require('telescope.builtin').live_grep({
          attach_mappings = function(prompt_bufnr, map)
            -- search the grep results with <C-g><C-g>
            -- ref: https://blog.atusy.net/2024/08/02/telescope-grep-refiement/
            map('i', '<C-g><C-g>', function()
              require('telescope.actions').send_to_qflist(prompt_bufnr)
              require('telescope.builtin').quickfix()
            end)
            return true
          end,
        })
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
  end,
}
