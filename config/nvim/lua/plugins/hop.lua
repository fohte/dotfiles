return {
  'smoka7/hop.nvim',
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
        '<Leader>j',
        function()
          require('hop').hint_lines({ direction = require('hop.hint').HintDirection.AFTER_CURSOR })
        end,
      },
      {
        '<Leader>k',
        function()
          require('hop').hint_lines({ direction = require('hop.hint').HintDirection.BEFORE_CURSOR })
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
