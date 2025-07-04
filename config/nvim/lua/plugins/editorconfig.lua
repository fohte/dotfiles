return {
  'editorconfig/editorconfig-vim',
  version = 'v1.2.1',
  config = function()
    vim.g.EditorConfig_exclude_patterns = { '\\.git/.*\\.diff' }
  end,
}
