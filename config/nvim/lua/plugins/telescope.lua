return {
  'nvim-telescope/telescope.nvim',
  dependencies = {
    { 'nvim-lua/plenary.nvim' },
    { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
    { 'fdschmidt93/telescope-egrepify.nvim' },
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
    {
      '<Leader>ed',
      function()
        local base_branch = vim.fn.system('git main'):gsub('%s+', '')
        local base = vim.fn.system('git merge-base origin/' .. base_branch .. ' HEAD'):gsub('%s+', '')
        if vim.v.shell_error ~= 0 then
          vim.notify('Failed to get merge-base with origin/' .. base_branch, vim.log.levels.ERROR)
          return
        end
        local diff_previewer = require('telescope.previewers').new_buffer_previewer({
          title = 'Diff Preview',
          define_preview = function(self, entry)
            require('telescope.previewers.utils').job_maker(
              { 'git', 'diff', base .. '...HEAD', '--', entry.value },
              self.state.bufnr,
              {
                callback = function(bufnr)
                  vim.bo[bufnr].filetype = 'diff'
                end,
              }
            )
          end,
        })
        require('telescope.builtin').find_files({
          prompt_title = 'Diff files (origin/' .. base_branch .. '...HEAD)',
          find_command = { 'git', 'diff', '--name-only', base .. '...HEAD' },
          previewer = diff_previewer,
        })
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
