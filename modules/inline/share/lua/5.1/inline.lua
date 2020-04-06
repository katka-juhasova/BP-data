local hash32
hash32 = require("murmurhash3").hash32
local Inline
do
  local _class_0
  local _base_0 = {
    css = function(self, str)
      local name = self:getUniqueClassName(str)
      self.__class.styles = self.__class.styles .. " ." .. tostring(name) .. " {" .. tostring(str) .. "}"
      return name
    end,
    stylesheet = function(self)
      return self.__class.styles
    end,
    getUniqueClassName = function(self, str)
      local h = self:hash(str)
      while self.__class.classNames[h] ~= nil do
        h = h + 1
      end
      self.__class.classNames.h = 1
      return "inline-css-" .. tostring(h)
    end,
    hash = function(self, str)
      return hash32(str)
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function() end,
    __base = _base_0,
    __name = "Inline"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  local self = _class_0
  self.styles = ""
  self.classNames = { }
  Inline = _class_0
  return _class_0
end
