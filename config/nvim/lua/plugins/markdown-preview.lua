return {
  'iamcco/markdown-preview.nvim',
  ft = 'markdown',
  cmd = 'MarkdownPreview',
  build = function ()
    vim.fn['mkdp#util#install']()
  end,
}
