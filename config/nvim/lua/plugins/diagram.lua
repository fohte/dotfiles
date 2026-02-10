return {
  {
    '3rd/image.nvim',
    lazy = true,
    opts = {
      -- Not officially supported by image.nvim but works with Ghostty/WezTerm.
      -- Switch to 'sixel' if images break.
      backend = 'kitty',
      -- Use ImageMagick CLI to avoid luarocks Lua 5.1 dependency
      processor = 'magick_cli',
      tmux_show_only_in_active_window = true,
      editor_only_render_when_focused = true,
    },
  },
  {
    '3rd/diagram.nvim',
    ft = 'markdown',
    dependencies = {
      { '3rd/image.nvim' },
    },
    opts = {
      renderer_options = {
        mermaid = {
          -- Pass options via cli_args to avoid shell comment interpretation.
          -- diagram.nvim builds the command as an unquoted string for jobstart,
          -- so '#' in background color truncates all subsequent arguments.
          cli_args = { '-t', 'dark', '-b', "'#000000'", '-s', '3' },
        },
      },
    },
  },
}
