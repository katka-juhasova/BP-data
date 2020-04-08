local debugkit = require("debugkit")
local unpack = unpack or table.unpack
local DEBUG = false
local DEBUG_INSPECT = DEBUG and require("inspect") or setmetatable({ }, {
  __call = function() end
})
local DEBUG_DEPTH = 5
local DEBUG_KEYWORDS = { }
local DEBUG_COLORS = {
  ["==>"] = "yellow",
  ["->"] = "green",
  ["*"] = "magenta",
  ["::"] = "blue",
  ["!!"] = "red"
}
local DEBUG_FI
DEBUG_FI = function(self, path)
  local i = DEBUG_INSPECT
  local _exp_0 = path[#path]
  if i.key == _exp_0 then
    local lk = path[#path - 1]
    if lk == "__tostring" then
      return nil
    end
    if lk == "__call" then
      return nil
    end
    if lk == "__parent" then
      return nil
    end
    if lk == "instances" then
      return nil
    end
    if lk == "safe" then
      return nil
    end
    if lk == "silent" then
      return nil
    end
    if lk == "__sig" then
      return nil
    end
    return self
  elseif i.metatable == _exp_0 then
    return self
  else
    return self
  end
end
local mapM, doInstant, finspect, fprint, filterKeywords, fsprint, cfsprint, color, colorall
do
  local _obj_0 = debugkit(DEBUG)
  mapM, doInstant, finspect, fprint, filterKeywords, fsprint, cfsprint, color, colorall = _obj_0.mapM, _obj_0.doInstant, _obj_0.finspect, _obj_0.fprint, _obj_0.filterKeywords, _obj_0.fsprint, _obj_0.cfsprint, _obj_0.color, _obj_0.colorall
end
doInstant()
finspect()()()()
local y = ((finspect(DEBUG_INSPECT))(DEBUG_FI))(DEBUG_DEPTH)
local p = (cfsprint(color(DEBUG_COLORS)))(DEBUG_KEYWORDS)
return {
  p = p,
  y = y,
  colorall = colorall
}
