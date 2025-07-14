return {
  { 'kana/vim-operator-user', commit = 'c3dfd41c1ed516b4b901c97562e644de62c367aa' }, -- renovate: branch=master
  {
    'kana/vim-operator-replace',
    commit = '1345a556a321a092716e149d4765a5e17c0e9f0f', -- renovate: branch=master
    dependencies = { 'kana/vim-operator-user' },
    keys = {
      { 'p', '<Plug>(operator-replace)', mode = { 'v' } },
    },
  },
  {
    'emonkak/vim-operator-sort',
    commit = '0c72bc4e3db9fc873b64baa5e4002f396a971369', -- renovate: branch=master
    dependencies = { 'kana/vim-operator-user' },
    keys = {
      { 'so', '<Plug>(operator-sort)', mode = { 'n', 'v', 'o' } },
    },
  },
  {
    'rhysd/vim-operator-surround',
    commit = '80337a40a829cfc77b065a71d8a609e2ad7d2c8b', -- renovate: branch=master
    dependencies = { 'kana/vim-operator-user' },
    keys = {
      { 'sa', '<Plug>(operator-surround-append)', mode = { 'n', 'v', 'o' } },
      { 'sd', '<Plug>(operator-surround-delete)a', mode = { 'n', 'v', 'o' } },
      { 'sr', '<Plug>(operator-surround-replace)a', mode = { 'n', 'v', 'o' } },
    },
  },
}
