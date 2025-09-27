return {
  'NeogitOrg/neogit',
  commit = 'add70101fab5913cad33ab2f84f1a6ee092e7220', -- renovate: branch=master
  dependencies = {
    { 'nvim-lua/plenary.nvim', commit = 'b9fd5226c2f76c951fc8ed5923d85e4de065e509' }, -- required -- renovate: branch=master
    { 'nvim-telescope/telescope.nvim', commit = 'b4da76be54691e854d3e0e02c36b0245f945c2c7' }, -- optional -- renovate: branch=master
    'sindrets/diffview.nvim', -- optional
  },
  config = function()
    require('neogit').setup({
      -- default: ascii
      -- unicode is the graph like https://github.com/rbong/vim-flog
      graph_style = 'unicode',

      commit_editor = {
        kind = 'tab',
        staged_diff_split_kind = 'vsplit',
      },
      log_view = {
        kind = 'auto',
      },
      popup = {
        kind = 'floating',
      },
      commit_popup = {
        kind = 'floating',
      },

      integrations = {
        telescope = true,
        diffview = true,
      },

      mappings = {
        status = {
          ['y'] = 'YankSelected', -- Use 'y' to copy commit hash
        },
      },

      -- Add custom actions to diff popup
      builders = {
        NeogitDiffPopup = function(builder)
          -- Add action to diff against master
          builder:action('m', 'master...HEAD', function(popup)
            popup:close()
            require('neogit.integrations.diffview').open('range', 'master...HEAD')
          end)
          -- Add action to diff against origin/master
          builder:action('M', 'origin/master...HEAD', function(popup)
            popup:close()
            require('neogit.integrations.diffview').open('range', 'origin/master...HEAD')
          end)
          return builder
        end,
      },
    })
  end,
  keys = {
    { '<Leader>nt', ':Neogit<CR>', mode = 'n', silent = true },
    { '<Leader>nc', ':Neogit commit<CR>', mode = 'n', silent = true },
    { '<Leader>nd', ':Neogit diff<CR>', mode = 'n', silent = true },
  },
}
