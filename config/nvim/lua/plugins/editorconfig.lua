return {
  'editorconfig/editorconfig-vim',
  commit = '6a58b7c11f79c0e1d0f20533b3f42f2a11490cf8',
  config = function()
    vim.g.EditorConfig_exclude_patterns = { '\\.git/.*\\.diff' }
  end,
}
