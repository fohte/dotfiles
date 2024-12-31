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
    ['.themisrc'] = 'vim',
    ['.babelrc'] = 'json',
    ['.prettierrc'] = 'json',
    ['Jenkinsfile'] = 'groovy',
    ['Steepfile'] = 'ruby',
  },
  pattern = {
    -- `.env.*`
    ['%.env%..*'] = 'sh',
    -- `Dockerfile.*`
    ['Dockerfile%..*'] = 'dockerfile',
    -- `.github/workflows/*.yml`
    ['.*/%.github/workflows/.*%.yml'] = 'yaml.actions',
  },
})
