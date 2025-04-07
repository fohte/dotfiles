return {
  'windwp/nvim-autopairs',
  -- renovate: datasource=github-releases depName=windwp/nvim-autopairs
  commit = '48ca9aaee733911424646cb1605f27bc01dedbe3',
  config = function()
    require('nvim-autopairs').setup()
  end,
}
