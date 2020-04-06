local require = require
local Action = require("wtf.core.classes.action")
local cjson = require("cjson")
local tools = require("wtf.core.tools")

local _M = Action:extend()
_M.name = "html_response"

function _M:act(...)
  local err = tools.error
  local readfile = tools.readfile
  local ngx = ngx
  local pairs = pairs
  local response = ""
  local policy = self:get_policy()
  
  local name = self:get_optional_parameter('name') or self.name
  local code = self:get_optional_parameter('code') or ngx.HTTP_OK
  local template = self:get_mandatory_parameter('template')
  local headers = self:get_optional_parameter('headers') or {}
  
  response = readfile(template)
  
  ngx.status = code
  ngx.header["Content-Type"] = "text/html"
  for h_name, h_value in pairs(headers) do
    ngx.header[h_name] = h_value
  end
  ngx.say(response)
  ngx.exit(ngx.status)
  
end

return _M