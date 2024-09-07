local linters = {}

linters['eslint'] = require('efmls-configs.linters.eslint_d')
-- workaround for flat config
-- https://github.com/mantoni/eslint_d.js/pull/282
linters['eslint'].lintCommand = string.format('%s %s', 'env ESLINT_USE_FLAT_CONFIG=true', linters['eslint'].lintCommand)

linters['shellcheck'] = require('efmls-configs.linters.shellcheck')

linters['textlint'] = require('efmls-configs.linters.textlint')

linters['actionlint'] = require('efmls-configs.linters.actionlint')

linters['golangci-lint'] = require('efmls-configs.linters.golangci_lint')

return linters
