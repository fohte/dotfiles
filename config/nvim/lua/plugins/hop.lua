return {
  'smoka7/hop.nvim',
  commit = '2254e0b3c8054b9ee661c9be3cb201d4b3384d8e', -- renovate: branch=master
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
