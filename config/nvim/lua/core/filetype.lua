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
    ['.babelrc'] = 'json',
    ['.envrc'] = 'bash',
    ['.prettierrc'] = 'json',
    ['.themisrc'] = 'vim',
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
