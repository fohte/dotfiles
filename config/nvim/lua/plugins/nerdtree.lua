return {
  'scrooloose/nerdtree',
  dependencies = {
    { 'Xuyuanp/nerdtree-git-plugin' },
  },
  config = function()
    vim.g.NERDTreeShowHidden = 1
    vim.g.NERDTreeIgnore = {
      '\\.DS_Store$',
      '\\.git$',
      '\\.vimsessions$',
      'node_modules$',
    }
  end,
  cmd = { 'NERDTreeToggle', 'NERDTreeFind' },
  keys = {
    { '<Leader>nt', ':NERDTreeToggle<CR>', mode = 'n' },
    { '<Leader>nf', ':NERDTreeFind<CR>', mode = 'n' },
  },
}
