return {
  'kana/vim-operator-user',
  commit = 'c3dfd41c1ed516b4b901c97562e644de62c367aa',
  {
    'kana/vim-operator-replace',
    commit = '1345a556a321a092716e149d4765a5e17c0e9f0f',
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
