return {
  'smoka7/hop.nvim',
  config = function()
    require('hop').setup({
      keys = 'aoeusnth',
    })
  end,
  keys = function()
    return {
      {
        '<Leader>n',
        function()
          local current_search = vim.fn.getreg('/')
          require('hop').hint_patterns({}, current_search)
        end,
      },
    }
  end,
}
