return {
  'kana/vim-operator-user',
  {
    'kana/vim-operator-replace',
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
  {
    'tyru/caw.vim',
    dependencies = { 'kana/vim-operator-user' },
    init = function()
      vim.g.caw_operator_keymappings = 1
    end,
    keys = {
      { '-', '<Plug>(caw:hatpos:toggle:operator)', mode = { 'n', 'v', 'o' } },
    },
  },
  {
    'fohte/vim-operator-case',
    dependencies = { 'kana/vim-operator-user' },
    keys = {
      { 'gcc', '<Plug>(operator-case-camelize)', mode = { 'n', 'v', 'o' } },
      { 'gcp', '<Plug>(operator-case-pascalize)', mode = { 'n', 'v', 'o' } },
      { 'gcs', '<Plug>(operator-case-snakenize)', mode = { 'n', 'v', 'o' } },
      { 'gcC', '<Plug>(operator-case-constantize)', mode = { 'n', 'v', 'o' } },
    },
  },
}
