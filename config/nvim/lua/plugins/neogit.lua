return {
  'NeogitOrg/neogit',
  commit = 'e3c148905c334c886453df1490360ebb1a2ba2ed',
  dependencies = {
    { 'nvim-lua/plenary.nvim', commit = '857c5ac632080dba10aae49dba902ce3abf91b35' }, -- required
    { 'nvim-telescope/telescope.nvim', commit = 'b4da76be54691e854d3e0e02c36b0245f945c2c7' }, -- optional
    { 'sindrets/diffview.nvim', commit = '4516612fe98ff56ae0415a259ff6361a89419b0a' }, -- optional
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
