vim.filetype.add({
  extension = {
    gemfile = 'ruby',
    prisma = 'prisma',
    tsx = 'typescript.tsx',
    vimspec = 'vim',
    jsonnet = 'jsonnet',
    dockerfile = 'dockerfile',
    re = 'review',
    -- workaround: Grafana Alloy config syntax is not HCL but it's similar
    alloy = 'hcl',
  },
  filename = {
    ['.babelrc'] = 'jsonc',
    ['.envrc'] = 'bash',
    ['.prettierrc'] = 'jsonc',
    ['.themisrc'] = 'vim',
    ['Jenkinsfile'] = 'groovy',
    ['Steepfile'] = 'ruby',
    ['tsconfig.json'] = 'jsonc',
  },
  pattern = {
    -- `.env.*`
    ['%.env%..*'] = 'sh',
    -- `Dockerfile.*`
    ['Dockerfile%..*'] = 'dockerfile',
    -- `.github/workflows/*.yml`
    ['.*/%.github/workflows/.*%.yml'] = 'yaml.actions',
    -- `tsconfig*.json`
    ['tsconfig.*%.json'] = 'jsonc',
    -- PR review thread markdown (detected by `pulled_at:` in frontmatter)
    ['.*%.md'] = {
      priority = -math.huge,
      function(path, bufnr)
        local lines = vim.api.nvim_buf_get_lines(bufnr, 0, 5, false)
        for _, line in ipairs(lines) do
          if line:match('^pulled_at:') then
            return 'pr_review'
          end
        end
      end,
    },
  },
})
