return {
  'kevinhwang91/nvim-ufo',
  commit = 'd31e2a9fd572a25a4d5011776677223a8ccb7e35', -- renovate: branch=main
  dependencies = {
    { 'kevinhwang91/promise-async', commit = '119e8961014c9bfaf1487bf3c2a393d254f337e2' }, -- renovate: branch=main
  },
  config = function()
    vim.keymap.set('n', 'zR', require('ufo').openAllFolds)
    vim.keymap.set('n', 'zM', require('ufo').closeAllFolds)

    require('ufo').setup({
      -- disable auto folding
      provider_selector = function()
        return ''
      end,
    })
  end,
}
