return {
  'scrooloose/nerdtree',
  dependencies = {
    { 'Xuyuanp/nerdtree-git-plugin' }
  },
  config = function()
    vim.fn['util#source_plugin_config']('nerdtree.rc.vim')
  end,
}
