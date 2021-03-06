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
local sqrt = math.sqrt

local super = tuple3
local class = { is_point3 = true }
local metatable = { __tostring = super.to_string }

-- a:distance_squared(point3 b)
function class.distance_squared(a, b)
  local x = a[1] - b[1]
  local y = a[2] - b[2]
  local z = a[3] - b[3]
  return x * x + y * y + z * z
end

-- a:distance(point3 b)
function class.distance(a, b)
  local x = a[1] - b[1]
  local y = a[2] - b[2]
  local z = a[3] - b[3]
  return sqrt(x * x + y * y + z * z)
end

-- a:distance_l1(point3 b)
function class.distance_l1(a, b)
  local x = a[1] - b[1]
  local y = a[2] - b[2]
  local z = a[3] - b[3]
  if x < 0 then x = -x end
  if y < 0 then y = -y end
  if z < 0 then z = -z end
  return x + y + z
end

-- a:distance_linf(point3 b)
function class.distance_linf(a, b)
  local x = a[1] - b[1]
  local y = a[2] - b[2]
  local z = a[3] - b[3]
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

-- a:project(point3 b) [EX]
-- a:project(point4 b)
function class.project(a, b)
  if #b == 3 then
    local d = b[3]
    a[1] = b[1] / d
    a[2] = b[2] / d
    a[3] = 1
    return a
  else
    local d = b[4]
    a[1] = b[1] / d
    a[2] = b[2] / d
    a[3] = b[3] / d
    return a
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
      a[3] = b[3] or 1
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

-- class(number b, number c, number d)
-- class(tuple3 b)
-- class(tuple2 b) [EX]
-- class()
return setmetatable(class, {
  __index = super;
  __call = function (_, ...)
    return setmetatable(class.set({}, ...), metatable)
  end;
})
