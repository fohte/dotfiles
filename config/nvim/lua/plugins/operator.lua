return {
  'kana/vim-operator-user',
  version = '0.1.0',
  {
    'kana/vim-operator-replace',
    version = '0.0.5',
    dependencies = { 'kana/vim-operator-user' },
    keys = {
      { 'p', '<Plug>(operator-replace)', mode = { 'v' } },
    },
  },
  {
    'emonkak/vim-operator-sort',
    dependencies = { 'kana/vim-operator-user' },
    keys = {
      { 'so', '<Plug>(operator-sort)', mode = { 'n', 'v', 'o' } },
    },
  },
  {
    'rhysd/vim-operator-surround',
    dependencies = { 'kana/vim-operator-user' },
    keys = {
      { 'sa', '<Plug>(operator-surround-append)', mode = { 'n', 'v', 'o' } },
      { 'sd', '<Plug>(operator-surround-delete)a', mode = { 'n', 'v', 'o' } },
      { 'sr', '<Plug>(operator-surround-replace)a', mode = { 'n', 'v', 'o' } },
    },
  },
}
