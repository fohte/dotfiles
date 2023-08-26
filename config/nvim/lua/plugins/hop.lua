return {
  'phaazon/hop.nvim',
  config = function()
    require('hop').setup({
      keys = 'etuhonas.c,rpg',
    })
  end,
  keys = function()
    return {
      {
        '<Leader>c',
        function()
          require('hop').hint_char1()
        end,
      },
      {
        '<Leader>l',
        function()
          require('hop').hint_lines_skip_whitespace()
        end,
      },
      {
        '<Leader>w',
        function()
          require('hop').hint_words()
        end,
      },
    }
  end,
}
