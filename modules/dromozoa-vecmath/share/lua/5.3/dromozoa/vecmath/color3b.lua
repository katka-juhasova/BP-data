-- Copyright (C) 2018 Tomoyuki Fujimori <moyu@dromozoa.com>
--
-- This file is part of dromozoa-vecmath.
--
-- dromozoa-vecmath is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- dromozoa-vecmath is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with dromozoa-vecmath.  If not, see <http://www.gnu.org/licenses/>.

local color3 = require "dromozoa.vecmath.color3"
local colors = require "dromozoa.vecmath.colors"

local rawget = rawget
local rawset = rawset
local setmetatable = setmetatable
local type = type

-- a:to_string()
local function to_string(a)
  local x = a[1]
  local y = a[2]
  local z = a[3]

  if x < 0 then x = 0 elseif x > 255 then x = 255 end
  if y < 0 then y = 0 elseif y > 255 then y = 255 end
  if z < 0 then z = 0 elseif z > 255 then z = 255 end

  if x % 1 == 0 and y % 1 == 0 and z % 1 == 0 then
    if x % 17 == 0 and y % 17 == 0 and z % 17 == 0 then
      return ("#%01X%01X%01X"):format(x / 17, y / 17, z / 17)
    else
      return ("#%02X%02X%02X"):format(x, y, z)
    end
  else
    return ("rgb(%.17g%%,%.17g%%,%.17g%%)"):format(x / 2.55, y / 2.55, z / 2.55)
  end
end

-- a:set_color3f(color3f b)
local function set_color3f(a, b)
  a[1] = b[1] * 255
  a[2] = b[2] * 255
  a[3] = b[3] * 255
  return a
end

local super = color3
local class = {
  is_color3b = true;
  to_string = to_string;
  set_color3f = set_color3f;
}
local metatable = {
  __tostring = to_string;
  ["dromozoa.dom.is_serializable"] = true;
}

-- a:set(number b, number y, number z)
-- a:set(string b)
-- a:set(color3f b)
-- a:set(tuple3 b)
-- a:set()
function class.set(a, b, y, z)
  if b then
    if y then
      a[1] = b
      a[2] = y
      a[3] = z
      return a
    else
      if type(b) == "string" then
        local c = colors[b] or colors.transparent
        a[1] = c[1]
        a[2] = c[2]
        a[3] = c[3]
        return a
      elseif b.is_color3f then
        return set_color3f(a, b)
      else
        a[1] = b[1]
        a[2] = b[2]
        a[3] = b[3]
        return a
      end
    end
  else
    a[1] = 0
    a[2] = 0
    a[3] = 0
    return a
  end
end

function metatable.__index(a, key)
  local value = class[key]
  if value then
    return value
  else
    return rawget(a, class.index[key])
  end
end

function metatable.__newindex(a, key, value)
  rawset(a, class.index[key], value)
end

-- a:set(number b, number y, number z)
-- a:set(string b)
-- a:set(color3f b)
-- a:set(tuple3 b)
-- a:set()
return setmetatable(class, {
  __index = super;
  __call = function (_, ...)
    return setmetatable(class.set({}, ...), metatable)
  end;
})
