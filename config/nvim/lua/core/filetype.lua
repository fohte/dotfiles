vim.filetype.add({
  extension = {
    gemfile = 'ruby',
    prisma = 'prisma',
    tsx = 'typescript.tsx',
    vimspec = 'vim',
    jsonnet = 'jsonnet',
    dockerfile = 'dockerfile',
  },
  filename = {
    ['.themisrc'] = 'vim',
    ['.babelrc'] = 'json',
    ['.prettierrc'] = 'json',
    ['Jenkinsfile'] = 'groovy',
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
