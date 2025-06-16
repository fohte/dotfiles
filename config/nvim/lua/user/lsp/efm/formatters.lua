local formatters = {}

formatters['eslint'] = require('efmls-configs.formatters.eslint_d')
-- workaround for flat config
-- https://github.com/mantoni/eslint_d.js/pull/282
formatters['eslint'].formatCommand =
  string.format('%s %s', 'env ESLINT_USE_FLAT_CONFIG=true', formatters['eslint'].formatCommand)

formatters['prettier'] = require('efmls-configs.formatters.prettier')

formatters['shfmt'] = require('efmls-configs.formatters.shfmt')

formatters['stylua'] = require('efmls-configs.formatters.stylua')

formatters['terraform'] = require('efmls-configs.formatters.terraform_fmt')

formatters['ruff'] = require('efmls-configs.formatters.ruff')

formatters['goimports'] = require('efmls-configs.formatters.goimports')

formatters['textlint'] = require('user.lsp.efm.formatters.textlint')

formatters['jsonnet'] = require('user.lsp.efm.formatters.jsonnet')

return formatters
