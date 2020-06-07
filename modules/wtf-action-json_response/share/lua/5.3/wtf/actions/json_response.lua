local require = require
local Action = require("wtf.core.classes.action")
local cjson = require("cjson")

local _M = Action:extend()
_M.name = "json_response"

function _M:act(...)
  local select = select
  local ngx = ngx
  local response = ""
  local payload = select(1, ...)
  
  local code = self:get_optional_parameter('code') or ngx.HTTP_OK
  
  response = cjson.encode(payload)
  
  ngx.status = code
  ngx.header["Content-Type"] = "application/json"
  ngx.say(response)
  ngx.exit(ngx.status)
  
end

return _M