return {
  'RRethy/nvim-base16',
  config = function()
    vim.cmd.colorscheme('base16-material-darker')

    vim.api.nvim_set_hl(0, 'IncSearch', { bg = '#444444', fg = 'none' })
    vim.api.nvim_set_hl(0, 'Search', { link = 'IncSearch' })
    vim.api.nvim_set_hl(0, 'MatchParen', { link = 'Number' })
    vim.api.nvim_set_hl(0, 'LineNr', { fg = '#444444' })
    vim.api.nvim_set_hl(0, 'VertSplit', { fg = '#444444' })

    -- make transparent background (use terminal bacgkground color)
    vim.api.nvim_set_hl(0, 'Normal', { bg = 'none' })
  end,
}
