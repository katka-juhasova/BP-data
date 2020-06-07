local require = require
local Action = require("wtf.core.classes.action")

local _M = Action:extend()
_M.name = "redirect"

function _M:act(...)
  local select = select
  local ngx = ngx
  local url = select(1, ...)
  
  return ngx.redirect(url, ngx.HTTP_MOVED_TEMPORARILY)
  
end

return _M