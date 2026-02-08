return {
  {
    '3rd/image.nvim',
    lazy = true,
    opts = {
      -- WezTerm's kitty graphics protocol support is unofficial but mostly works.
      -- Switch to 'sixel' if images break or performance is poor.
      backend = 'kitty',
      -- Use ImageMagick CLI instead of the magick luarock to avoid Lua 5.1 dependency
      processor = 'magick_cli',
      -- Prevent images from leaking into other tmux windows/panes
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
