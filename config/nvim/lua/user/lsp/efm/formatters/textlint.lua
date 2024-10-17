-- Metadata
-- languages: misc
-- url: https://textlint.github.io/

local fs = require('efmls-configs.fs')

local formatter = 'textlint'
-- `--dry-run` is used to prevent textlint from writing to the `--stdin-filename` file
local args = '--fix --dry-run --format fixed-result --stdin --stdin-filename ${INPUT}'
local command = string.format('%s %s', fs.executable(formatter, fs.Scope.NODE), args)

return {
  formatCommand = command,
  formatStdin = true,
}
