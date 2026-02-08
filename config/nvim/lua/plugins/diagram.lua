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
          theme = 'dark',
        },
      },
    },
  },
}
