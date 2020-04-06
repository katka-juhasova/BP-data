local http = require 'resty.http'

local _M = {}

local PREFIX = 'X-'

function _M.execute(config)
  local httpc = http:new()
  local headers = ngx.req.get_headers()
  ngx.req.read_body()
  local body = ngx.var.request_body
  for key, value in pairs(config.headers or {}) do
    headers[key] = value
  end
  local port = ngx.var.server_port
  headers['X-Target-Method'] = ngx.var.request_method
  headers['X-Target-Scheme'] = ngx.var.scheme
  headers['X-Target-Host'] = ngx.var.host
  headers['X-Target-Port'] = port 
  headers['X-Target-Path'] = ngx.var.uri
  headers['X-Target-Uri'] = ngx.var.request_uri
  ngx.req.clear_header('Host')
  local res, err = httpc:request_uri(config.url, {
    method = config.method or ngx.var.request_method,
    ssl_verify = false,
    headers = headers,
    body = body,
    query = ngx.req.get_uri_args(),
  })
  if err ~= nil then
    ngx.status = ngx.HTTP_INTERNAL_SERVER_ERROR
    ngx.say(err)
    return ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
  end
  if res.status > 299 then
    ngx.status = res.status
    for key, value in pairs(res.headers) do
      ngx.header[key] = value
    end
    ngx.say(res.body)
    return ngx.exit(res.status)
  end
  ngx.req.set_header('Host', ngx.var.host)
  for key, value in pairs(res.headers) do
    if string.sub(key, 1, string.len(PREFIX)) == PREFIX then
      ngx.req.set_header(key, value)
    end
  end
end

return _M
