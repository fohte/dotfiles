return {
  'pwntester/octo.nvim',
  config = function()
    require('octo').setup()

    vim.api.nvim_create_autocmd('FileType', {
      pattern = 'octo',
      callback = function()
        vim.opt_local.conceallevel = 0
      end,
    })
  end,
}
