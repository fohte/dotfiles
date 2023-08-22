return {
  'RRethy/nvim-base16',
  config = function()
    local utils = require('utils')

    vim.cmd.colorscheme('base16-material-darker')

    vim.api.nvim_set_hl(0, 'IncSearch', { bg = '#444444', fg = 'none' })
    vim.api.nvim_set_hl(0, 'Search', { link = 'IncSearch' })
    vim.api.nvim_set_hl(0, 'MatchParen', { link = 'Number' })
    vim.api.nvim_set_hl(0, 'LineNr', { fg = '#444444' })
    vim.api.nvim_set_hl(0, 'VertSplit', { fg = '#444444' })

    -- make transparent background (use terminal bacgkground color)
    local transparent_targets = {
      'Normal',
      'NormalNC',
      'SignColumn',
    }
    for _, target in ipairs(transparent_targets) do
      local current = vim.api.nvim_get_hl(0, { name = target })
      vim.api.nvim_set_hl(0, target, utils.mergeTables(current, { bg = 'none' }))
    end
  end,
}
