return {
  'neoclide/coc.nvim',
  branch = 'release',
  config = function()
    vim.fn['util#source_plugin_config']('coc.rc.vim')
  end,
}
