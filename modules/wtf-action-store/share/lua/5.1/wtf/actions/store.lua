local require = require
local cjson = require("cjson")
local tools = require("wtf.core.tools")
local Action = require("wtf.core.classes.action")

local _M = Action:extend()
_M.name = "store"

function _M:init( ... )
  local select = select
  local instance = select(1, ...)
  self.instance = instance
end

function _M:act(...)
  local rnd = tools.random_string
  local select = select
  local id, data
  
  local storage_name = self:get_mandatory_parameter('storage')
  local storage = self.instance:get_storage(storage_name)
  local p1, p2 = select(1, ...)
  
  if p2 then
    id = p1
    data = p2
  else
    data = p1
    if data["id"] then
      id = data["id"]
    else
      id = rnd(32)
    end
  end

  storage:set(id, cjson.encode(data))

	return self
end

return _M

