local M = {}

local linters = require('user.lsp.efm.linters')
local formatters = require('user.lsp.efm.formatters')

M.languages = {}
M.filetypes = {}

function M.setup(options)
  for _, config in ipairs(options) do
    for _, language in ipairs(config.languages) do
      if not M.languages[language] then
        table.insert(M.filetypes, language)
      end

      if not M.languages[language] then
        M.languages[language] = {}
      end

      for _, linter in ipairs(config.linters or {}) do
        table.insert(M.languages[language], linters[linter])
      end

      for _, formatter in ipairs(config.formatters or {}) do
        table.insert(M.languages[language], formatters[formatter])
      end
    end
  end
end

return M
