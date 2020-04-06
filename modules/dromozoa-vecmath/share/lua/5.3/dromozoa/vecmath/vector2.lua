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

local tuple2 = require "dromozoa.vecmath.tuple2"

local rawget = rawget
local rawset = rawset
local setmetatable = setmetatable
local atan2 = math.atan2
local sqrt = math.sqrt

local super = tuple2
local class = { is_vector2 = true }
local metatable = { __tostring = super.to_string }

-- a:dot(vector2 b)
function class.dot(a, b)
  return a[1] * b[1] + a[2] * b[2]
end

-- a:length()
function class.length(a)
  local x = a[1]
  local y = a[2]
  return sqrt(x * x + y * y)
end

-- a:length_squared()
function class.length_squared(a)
  local x = a[1]
  local y = a[2]
  return x * x + y * y
end

-- a:length_l1() [EX]
function class.length_l1(a)
  local x = a[1]
  local y = a[2]
  if x < 0 then x = -x end
  if y < 0 then y = -y end
  return x + y
end

-- a:length_linf() [EX]
function class.length_linf(a)
  local x = a[1]
  local y = a[2]
  if x < 0 then x = -x end
  if y < 0 then y = -y end
  if x > y then
    return x
  else
    return y
  end
end

-- a:normalize(vector2 b)
-- a:normalize()
function class.normalize(a, b)
  if not b then
    b = a
  end
  local x = b[1]
  local y = b[2]
  local d = sqrt(x * x + y * y)
  a[1] = x / d
  a[2] = y / d
  return a
end

-- a:angle(vector2 b)
function class.angle(a, b)
  local ax = a[1]
  local ay = a[2]
  local bx = b[1]
  local by = b[2]
  local angle = atan2(ax * by - ay * bx, ax * bx + ay * by)
  if angle < 0 then
    return -angle
  else
    return angle
  end
end

-- a:cross(vector2 b) [EX]
function class.cross(a, b)
  return a[1] * b[2] - a[2] * b[1]
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

-- class(number b, number y)
-- class(tuple2 b)
-- class()
return setmetatable(class, {
  __index = super;
  __call = function (_, ...)
    return setmetatable(class.set({}, ...), metatable)
  end;
})
