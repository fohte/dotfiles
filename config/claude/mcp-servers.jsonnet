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
}
