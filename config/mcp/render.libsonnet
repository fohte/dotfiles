local pick(object, keys) = {
  [key]: object[key]
  for key in keys
  if std.objectHas(object, key)
};

local codexOAuth(oauth) =
  pick(oauth, ['client_id', 'callback_url', 'callback_port'])
  + (if std.objectHas(oauth, 'clientId') then { client_id: oauth.clientId } else {})
  + (if std.objectHas(oauth, 'callbackUrl') then { callback_url: oauth.callbackUrl } else {})
  + (if std.objectHas(oauth, 'callbackPort') then { callback_port: oauth.callbackPort } else {});

local codexServer(server) =
  pick(server, [
    'environment_id',
    'auth',
    'startup_timeout_sec',
    'tool_timeout_sec',
    'enabled',
    'required',
    'supports_parallel_tool_calls',
    'omit_tools_from',
    'enabled_tools',
    'disabled_tools',
    'scopes',
    'oauth_resource',
    'tools',
  ])
  + if std.objectHas(server, 'command') then
    pick(server, ['command', 'args', 'env', 'env_vars', 'cwd'])
  else
    pick(server, [
      'url',
      'bearer_token_env_var',
      'http_headers',
      'env_http_headers',
      'http_headers_helper',
    ])
    + (if std.objectHas(server, 'headersHelper') then
      { http_headers_helper: server.headersHelper }
    else {})
    + (if std.objectHas(server, 'headers') then { http_headers: server.headers } else {})
    + (if std.objectHas(server, 'oauth') then { oauth: codexOAuth(server.oauth) } else {});

{
  claude(servers):: servers,
  codex(servers):: {
    [name]: codexServer(servers[name])
    for name in std.objectFields(servers)
  },
}
