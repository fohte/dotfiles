return {
  'smoka7/hop.nvim',
  commit = '707049feaca9ae65abb3696eff9aefc7879e66aa', -- renovate: branch=master
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
