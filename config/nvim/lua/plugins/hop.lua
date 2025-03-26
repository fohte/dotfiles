return {
  'smoka7/hop.nvim',
  -- renovate: datasource=github-releases depName=smoka7/hop.nvim
  commit = '8f51ef02700bb3cdcce94e92eff16170a6343c4f',
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
