return {
  'w0rp/ale',
  config = function()
    vim.fn['util#source_plugin_config']('ale.rc.vim')
  end,
}
