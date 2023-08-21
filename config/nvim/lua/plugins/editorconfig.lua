return {
  'editorconfig/editorconfig-vim',
  config = function()
    vim.g.EditorConfig_exclude_patterns = { '\\.git/.*\\.diff' }
  end,
}
