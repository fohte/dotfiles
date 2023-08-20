return {
  'itchyny/lightline.vim',
  config = function()
    vim.fn['util#source_plugin_config']('lightline.rc.vim')
  end,
}
