
--[[
klesi.lua - Simple but Powerful OOP Library
By Samuel Hunter <lawful.lazy@gmail.com>

Check it out on Git!
https://github.com/Lawful-Lazy/lua-klesi

Uses the MIT License.
https://opensource.org/licenses/MIT

]]--

local function new(class, ...)
  local obj = {}
  local hexcode = tostring(obj):sub(8)

  obj.class = class
  setmetatable(obj, class)

  if class.new then
    class.new(obj, ...)
  else
    new(class.super, ...)
  end

  function obj.gethexcode() return hexcode end

  return obj
end

local function extend(super)
  local class = {}
  local mt = {}
  
  class.__index = class
  class.super = super
  mt.__index = mt
  mt.extend = extend
  setmetatable(class, mt)
  setmetatable(mt, class.super)

  function mt.__call(_, ...)
    return new(class, ...)
  end

  return class
end

local Object = extend(nil)
Object.super = Object

function Object:new() end

function Object:instanceof(class)
  local selfclass = self.class
  while selfclass ~= class do
    if selfclass == Object then return false end
    selfclass = selfclass.super
  end

  return true
end

function Object:__tostring()
  return self.gethexcode()
end

function Object:clone()
  local obj = {}
  for k,v in pairs(self) do
    obj[k] = v
  end
  setmetatable(obj, self.class)
  return obj
end

function Object:cast(class)
  assert(self:instanceof(class))
  local obj = self:clone()
  setmetatable(obj, class)
  obj.class = class
  return obj
end

return Object

