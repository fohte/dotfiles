return {
  'smoka7/hop.nvim',
  commit = '9c6a1dd9afb53a112b128877ccd583a1faa0b8b6',
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
