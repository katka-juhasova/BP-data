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

local tuple3 = require "dromozoa.vecmath.tuple3"

local rawget = rawget
local rawset = rawset
local setmetatable = setmetatable
local atan2 = math.atan2
local sqrt = math.sqrt

local super = tuple3
local class = { is_vector3 = true }
local metatable = { __tostring = super.to_string }

-- a:cross(vector3 b, vector3 c)
function class.cross(a, b, c)
  local bx = b[1]
  local by = b[2]
  local bz = b[3]
  local cx = c[1]
  local cy = c[2]
  local cz = c[3]
  a[1] = by * cz - bz * cy
  a[2] = bz * cx - bx * cz
  a[3] = bx * cy - by * cx
  return a
end

-- a:normalize(vector3 b)
-- a:normalize()
function class.normalize(a, b)
  if not b then
    b = a
  end
  local x = b[1]
  local y = b[2]
  local z = b[3]
  local d = sqrt(x * x + y * y + z * z)
  a[1] = x / d
  a[2] = y / d
  a[3] = z / d
  return a
end

-- a:dot(vector3 b)
function class.dot(a, b)
  return a[1] * b[1] + a[2] * b[2] + a[3] * b[3]
end

-- a:length_squared()
function class.length_squared(a)
  local x = a[1]
  local y = a[2]
  local z = a[3]
  return x * x + y * y + z * z
end

-- a:length()
function class.length(a)
  local x = a[1]
  local y = a[2]
  local z = a[3]
  return sqrt(x * x + y * y + z * z)
end

-- a:length_l1() [EX]
function class.length_l1(a)
  local x = a[1]
  local y = a[2]
  local z = a[3]
  if x < 0 then x = -x end
  if y < 0 then y = -y end
  if z < 0 then z = -z end
  return x + y + z
end

-- a:length_linf() [EX]
function class.length_linf(a)
  local x = a[1]
  local y = a[2]
  local z = a[3]
  if x < 0 then x = -x end
  if y < 0 then y = -y end
  if z < 0 then z = -z end
  if x > y then
    if x > z then
      return x
    else
      return z
    end
  else
    if y > z then
      return y
    else
      return z
    end
  end
end

-- a:angle(vector3 b)
function class.angle(a, b)
  local ax = a[1]
  local ay = a[2]
  local az = a[3]
  local bx = b[1]
  local by = b[2]
  local bz = b[3]
  local x = ay * bz - az * by
  local y = az * bx - ax * bz
  local z = ax * by - ay * bx
  local angle = atan2(sqrt(x * x + y * y + z * z), ax * bx + ay * by + az * bz)
  if angle < 0 then
    return -angle
  else
    return angle
  end
end

-- a:set(number b, number y, number z)
-- a:set(tuple3 b)
-- a:set(tuple2 b) [EX]
-- a:set()
function class.set(a, b, y, z)
  if b then
    if y then
      a[1] = b
      a[2] = y
      a[3] = z
      return a
    else
      a[1] = b[1]
      a[2] = b[2]
      a[3] = b[3] or 0
      return a
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

-- class(number b, number y, number z)
-- class(tuple3 b)
-- class(tuple2 b) [EX]
-- class()
return setmetatable(class, {
  __index = super;
  __call = function (_, ...)
    return setmetatable(class.set({}, ...), metatable)
  end;
})
