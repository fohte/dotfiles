return {
  'pwntester/octo.nvim',
  config = function()
    require('octo').setup({
      mappings_disable_default = true,
      mappings = {
        issue = {
          open_in_browser = { lhs = '<C-b>', desc = 'open issue in browser' },
          add_comment = { lhs = '<localleader>ca', desc = 'add comment' },
        },
      },
    })

    vim.api.nvim_create_autocmd('FileType', {
      pattern = 'octo',
      callback = function()
        vim.opt_local.conceallevel = 0
      end,
    })
  end,
}
