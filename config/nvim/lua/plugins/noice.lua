return {
  "folke/noice.nvim",
  event = "VeryLazy",
  dependencies = {
    "MunifTanjim/nui.nvim",
    {
      "rcarriga/nvim-notify",
      config = function()
        require('notify').setup({
          background_colour = "#000000",
          render = "compact",
          stages = "fade",
        })
      end,
    },
  },
  config = function()
    require('noice').setup()
  end,
}
