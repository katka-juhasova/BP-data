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
local sqrt = math.sqrt

local super = tuple2
local class = { is_point2 = true }
local metatable = { __tostring = super.to_string }

-- a:distance_squared(point2 b)
function class.distance_squared(a, b)
  local x = a[1] - b[1]
  local y = a[2] - b[2]
  return x * x + y * y
end

-- a:distance(point2 b)
function class.distance(a, b)
  local x = a[1] - b[1]
  local y = a[2] - b[2]
  return sqrt(x * x + y * y)
end

-- a:distance_l1(point2 b)
function class.distance_l1(a, b)
  local x = a[1] - b[1]
  local y = a[2] - b[2]
  if x < 0 then x = -x end
  if y < 0 then y = -y end
  return x + y
end

-- a:distance_linf(point2 b)
function class.distance_linf(a, b)
  local x = a[1] - b[1]
  local y = a[2] - b[2]
  if x < 0 then x = -x end
  if y < 0 then y = -y end
  if x > y then
    return x
  else
    return y
  end
end

-- a:project(point3 b) [EX]
function class.project(a, b)
  local d = b[3]
  a[1] = b[1] / d
  a[2] = b[2] / d
  return a
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
