return {
  'NeogitOrg/neogit',
  commit = 'a1bcc7b9ab5137f691dcac1e61d5a9b3e9a46507', -- renovate: branch=master
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
    })
  end,
  keys = {
    { '<Leader>nt', ':Neogit<CR>', mode = 'n', silent = true },
    { '<Leader>nc', ':Neogit commit<CR>', mode = 'n', silent = true },
    { '<Leader>nd', ':Neogit diff<CR>', mode = 'n', silent = true },
  },
}
