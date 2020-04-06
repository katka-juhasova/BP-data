local Ltn12 = require "ltn12"
local Json  = require "cjson"
local Http  = require "socket.http"
local Https = require "ssl.https"

local M = {}

function M.json (options)
  assert (type (options) == "table")
  local result = {}
  options.sink    = Ltn12.sink.table (result)
  options.method  = options.method  or "GET"
  options.body    = options.body    and Json.encode (options.body)
  options.source  = options.body    and Ltn12.source.string (options.body)
  options.headers = options.headers or {}
  options.headers ["Content-length"] = options.body and #options.body or 0
  options.headers ["Content-type"  ] = options.body and "application/json"
  options.headers ["Accept"        ] = "application/json"
  local http = options.url:match "https://"
           and Https
            or Http
  local _, status, _, _ = http.request (options)
  result = table.concat (result)
  if result then
    local ok, json = pcall (Json.decode, result)
    if ok then
      result = json
    end
  end
  return result, status
end

return M
