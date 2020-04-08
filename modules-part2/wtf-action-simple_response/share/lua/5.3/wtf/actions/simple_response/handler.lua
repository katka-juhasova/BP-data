local require = require
local Action = require("wtf.core.classes.action")
local tools = require("wtf.core.tools")

local _M = Action:extend()
_M.name = "simple_response"

function _M:act(...)
  local err = tools.error
  local readfile = tools.readfile
  local ngx = ngx
  local pairs = pairs
  local select = select
  local response = select(1, ...)
  local policy = self:get_policy()
  
  local name = self:get_optional_parameter('name') or self.name
  local code = self:get_optional_parameter('code') or ngx.HTTP_OK
  local headers = self:get_optional_parameter('headers') or {}
  
  ngx.status = code
  ngx.header["Content-Type"] = "text/plain"
  for h_name, h_value in pairs(headers) do
    ngx.header[h_name] = h_value
  end
  ngx.say(response)
  ngx.exit(ngx.status)
end

return _M