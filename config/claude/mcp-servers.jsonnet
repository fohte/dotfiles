local env(name) = std.extVar(name);

{
  context7: {
    type: 'stdio',
    command: 'npx',
    args: ['-y', '@upstash/context7-mcp', '--api-key', env('CONTEXT7_API_KEY')],
    env: {},
  },
  qmd: {
    type: 'stdio',
    command: 'qmd',
    args: ['mcp'],
    env: {},
  },
  codecov: {
    type: 'stdio',
    command: 'npx',
    args: [
      '-y',
      '@ivotoby/openapi-mcp-server',
      '--api-base-url', 'https://api.codecov.io/api/v2',
      '--openapi-spec', 'https://api.codecov.io/api/v2/schema',
      '--headers', 'Authorization:Bearer ' + env('CODECOV_TOKEN'),
      '--tools', 'dynamic',
      '--operation', 'get',
    ],
    env: {},
  },
}
