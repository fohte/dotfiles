return {
  'iamcco/markdown-preview.nvim',
  version = 'v0.0.10',
  ft = 'markdown',
  cmd = 'MarkdownPreview',
  build = function()
    vim.fn['mkdp#util#install']()
  end,
}
