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

local color4 = require "dromozoa.vecmath.color4"
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
  local w = a[4]

  if x < 0 then x = 0 elseif x > 1 then x = 1 end
  if y < 0 then y = 0 elseif y > 1 then y = 1 end
  if z < 0 then z = 0 elseif z > 1 then z = 1 end

  local bx = x * 255
  if bx % 1 == 0 then
    local by = y * 255
    if by % 1 == 0 then
      local bz = z * 255
      if bz % 1 == 0 then
        if w == 1 then
          if bx % 17 == 0 and by % 17 == 0 and bz % 17 == 0 then
            return ("#%01X%01X%01X"):format(bx / 17, by / 17, bz / 17)
          else
            return ("#%02X%02X%02X"):format(bx, by, bz)
          end
        else
          return ("rgba(%d,%d,%d,%.17g)"):format(bx, by, bz, w)
        end
      end
    end
  end
  if w == 1 then
    return ("rgb(%.17g%%,%.17g%%,%.17g%%)"):format(x * 100, y * 100, z * 100)
  else
    return ("rgba(%.17g%%,%.17g%%,%.17g%%,%.17g)"):format(x * 100, y * 100, z * 100, w)
  end
end

-- a:set_color4b(color4b b)
local function set_color4b(a, b)
  a[1] = b[1] / 255
  a[2] = b[2] / 255
  a[3] = b[3] / 255
  a[4] = b[4] / 255
  return a
end

-- a:set_color3b(color4b b)
local function set_color3b(a, b)
  a[1] = b[1] / 255
  a[2] = b[2] / 255
  a[3] = b[3] / 255
  a[4] = 1
  return a
end

local super = color4
local class = {
  is_color4f = true;
  to_string = to_string;
  set_color4b = set_color4b;
}
local metatable = {
  __tostring = to_string;
  ["dromozoa.dom.is_serializable"] = true;
}

-- a:set(number b, number y, number z, number w)
-- a:set(string b)
-- a:set(color4b b)
-- a:set(tuple4 b)
-- a:set(color3b b)
-- a:set(tuple3 b)
-- a:set()
function class.set(a, b, y, z, w)
  if b then
    if y then
      a[1] = b
      a[2] = y
      a[3] = z
      a[4] = w
      return a
    else
      if type(b) == "string" then
        local c = colors[b] or colors.transparent
        a[1] = c[1] / 255
        a[2] = c[2] / 255
        a[3] = c[3] / 255
        a[4] = c[4] / 255
        return a
      elseif b.is_color4b then
        return set_color4b(a, b)
      elseif b.is_color3b then
        return set_color3b(a, b)
      else
        a[1] = b[1]
        a[2] = b[2]
        a[3] = b[3]
        a[4] = b[4] or 1
        return a
      end
    end
  else
    a[1] = 0
    a[2] = 0
    a[3] = 0
    a[4] = 0
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

-- a:set(number b, number y, number z, number w)
-- a:set(string b)
-- a:set(color4b b)
-- a:set(tuple4 b)
-- a:set(color3b b)
-- a:set(tuple3 b)
-- a:set()
return setmetatable(class, {
  __index = super;
  __call = function (_, ...)
    return setmetatable(class.set({}, ...), metatable)
  end;
})
