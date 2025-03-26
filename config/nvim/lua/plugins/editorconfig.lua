return {
  'editorconfig/editorconfig-vim',
  -- renovate: datasource=github-releases depName=editorconfig/editorconfig-vim
  commit = '8b7da79e9daee7a3f3a8d4fe29886b9756305aff',
  config = function()
    vim.g.EditorConfig_exclude_patterns = { '\\.git/.*\\.diff' }
  end,
}
