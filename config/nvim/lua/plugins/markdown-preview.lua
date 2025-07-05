return {
  'iamcco/markdown-preview.nvim',
  commit = 'a923f5fc5ba36a3b17e289dc35dc17f66d0548ee',
  ft = 'markdown',
  cmd = 'MarkdownPreview',
  build = function()
    vim.fn['mkdp#util#install']()
  end,
}
