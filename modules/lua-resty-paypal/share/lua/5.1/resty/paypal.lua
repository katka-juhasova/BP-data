local http = require 'resty.http'
local json = json or require 'cjson'
local i  = require 'inspect'
local _M = { __VERSION = '0.1-0' }
local mt = { __index = _M }

local sandbox_url = 'https://api.sandbox.paypal.com/v1/'
local api_url = 'https://api.paypal.com/v1/'

function request(method, path, params)
  local httpc = http.new()
  local args  = {
    method = method,
    body = json.encode(params),
    ssl_verify = false,
    headers = {
      ['Content-Type']  = 'application/json',
      ['Authorization'] =  'Bearer ' .. _M.get_access_token()
    } 
  }
  local url = _M.create_url(path)
  local res, err = httpc:request_uri(url, args)
  if res.status == 201 or res.status == 200 then
    return json.decode(res.body) 
  else
    return nil, json.decode(res.body)
  end
end

function _M.new(config)
  if not config then error("Missing paypal config params") end
  if not config.client_id then error("Missing required paypal client_id") end
  if not config.secret then error("Missing require paypal secret") end

  _M.env = config.env or 'sandbox'
  _M.client_id = config.client_id
  _M.secret = config.secret
  return setmetatable(_M, mt)
end

function _M.create_url(path, params)
  local api = _M.env == 'sandbox' and sandbox_url or api_url
  local url = api .. path
  if params then url = url .. '?' .. ngx.encode_args(params or {}) end
  return url
end

function _M.get_access_token()
  local httpc = http.new()
  local args = {
    method = 'POST',
    body = "grant_type=client_credentials",
    ssl_verify = false,
    headers = { 
      ['Accept'] = 'application/json',
      ['Authorization'] = 'Basic ' .. ngx.encode_base64(_M.client_id .. ':' .. _M.secret)
    }
  } 
  local url = _M.create_url('oauth2/token')
  local res, err = httpc:request_uri(url, args) 
  if not res then return nil, err end
  if res.status == 200 then
    local body = json.decode(res.body)
    return body.access_token
  end 
end

function _M.get(self, api, args)
  return request('GET', api, args) 
end

function _M.post(self, api, args)
  return request('POST', api, args) 
end

function _M.put(self, api, args)
  return request('PUT', api, args) 
end

function _M.patch(self, api, args)
  return request('PATCH', api, args) 
end

function _M.delete(self, api, args)
  return request('DELETE', api, args) 
end

return _M
