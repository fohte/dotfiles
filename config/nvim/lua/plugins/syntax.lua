return {
  { 'pantharshit00/vim-prisma', ft = 'prisma' },
  { 'hashivim/vim-terraform', ft = { 'terraform', 'hcl' } },
  { 'tokorom/vim-review', ft = 'review' },
  {
    'tpope/vim-rails',
    ft = 'ruby',
  },
  {
    'davidmh/mdx.nvim',
    ft = 'mdx',
    config = true,
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
  },
}
