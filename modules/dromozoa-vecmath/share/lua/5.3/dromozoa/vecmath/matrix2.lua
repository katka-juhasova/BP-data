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

local svd2 = require "dromozoa.vecmath.svd2"

local type = type
local atan2 = math.atan2
local cos = math.cos
local sin = math.sin
local format = string.format

-- a:to_string()
local function to_string(a)
  return format("%.17g, %.17g\n%.17g, %.17g\n",
      a[1], a[2],
      a[3], a[4])
end

-- a:mul(number b, matrix2 c)
-- a:mul(matrix2 b, matrix2 c)
-- a:mul(number b)
-- a:mul(matrix2 b)
local function mul(a, b, c)
  if type(b) == "number" then
    if not c then
      c = a
    end
    a[1] = b * c[1]
    a[2] = b * c[2]
    a[3] = b * c[3]
    a[4] = b * c[4]
    return a
  else
    if not c then
      c = b
      b = a
    end
    local b11 = b[1]
    local b12 = b[2]
    local b21 = b[3]
    local b22 = b[4]

    local c11 = c[1]
    local c12 = c[2]
    local c21 = c[3]
    local c22 = c[4]

    a[1] = b11 * c11 + b12 * c21
    a[2] = b11 * c12 + b12 * c22
    a[3] = b21 * c11 + b22 * c21
    a[4] = b21 * c12 + b22 * c22
    return a
  end
end

-- a:mul_transpose_right(matrix2 b, matrix2 c)
local function mul_transpose_right(a, b, c)
  local b11 = b[1]
  local b12 = b[2]
  local b21 = b[3]
  local b22 = b[4]

  local c11 = c[1]
  local c12 = c[3]
  local c21 = c[2]
  local c22 = c[4]

  a[1] = b11 * c11 + b12 * c21
  a[2] = b11 * c12 + b12 * c22
  a[3] = b21 * c11 + b22 * c21
  a[4] = b21 * c12 + b22 * c22
  return a
end

-- a:normalize(matrix2 b)
-- a:normalize()
local function normalize(a, b)
  if not b then
    b = a
  end
  local u = { 1, 0, 0, 1 }
  local v = { 1, 0, 0, 1 }
  svd2({ b[1], b[2], b[3], b[4] }, u, v)
  return mul_transpose_right(a, u, v)
end

local class = {
  is_matrix2 = true;
  index = {
    1, 2, 3, 4,
    m11 = 1, m12 = 2,
    m21 = 3, m22 = 4,
  };
  to_string = to_string;
  mul = mul;
  mul_transpose_right = mul_transpose_right;
  normalize = normalize;
}
local metatable = { __tostring = to_string }

-- a:set_identity()
function class.set_identity(a)
  a[1] = 1
  a[2] = 0
  a[3] = 0
  a[4] = 1
  return a
end

-- a:set_scale(number scale)
function class.set_scale(a, scale)
  normalize(a)
  a[1] = a[1] * scale
  a[2] = a[2] * scale
  a[3] = a[3] * scale
  a[4] = a[4] * scale
  return a
end

-- a:get_scale()
function class.get_scale(a)
  return svd2{ a[1], a[2], a[3], a[4] }
end

-- a:add(number b, matrix2 c)
-- a:add(matrix2 b, matrix2 c)
-- a:add(number b)
-- a:add(matrix2 b)
function class.add(a, b, c)
  if type(b) == "number" then
    if not c then
      c = a
    end
    a[1] = b + c[1]
    a[2] = b + c[2]
    a[3] = b + c[3]
    a[4] = b + c[4]
    return a
  else
    if not c then
      c = b
      b = a
    end
    a[1] = b[1] + c[1]
    a[2] = b[2] + c[2]
    a[3] = b[3] + c[3]
    a[4] = b[4] + c[4]
    return a
  end
end

-- a:sub(matrix2 b, matrix2 c)
-- a:sub(matrix2 b)
function class.sub(a, b, c)
  if not c then
    c = b
    b = a
  end
  a[1] = b[1] - c[1]
  a[2] = b[2] - c[2]
  a[3] = b[3] - c[3]
  a[4] = b[4] - c[4]
  return a
end

-- a:transpose(matrix2 b)
-- a:transpose()
function class.transpose(a, b)
  if b then
    a[2], a[3] = b[3], b[2]
    a[1] = b[1]
    a[4] = b[4]
    return a
  else
    a[2], a[3] = a[3], a[2]
    return a
  end
end

-- a:set(number b, number m12, ...)
-- a:set(number b)
-- a:set(matrix2 b)
-- a:set()
function class.set(a, b, m12, m21, m22)
  if b then
    if m12 then
      a[1] = b
      a[2] = m12
      a[3] = m21
      a[4] = m22
      return a
    else
      if type(b) == "number" then
        a[1] = b
        a[2] = 0
        a[3] = 0
        a[4] = b
        return a
      else
        a[1] = b[1]
        a[2] = b[2]
        a[3] = b[3]
        a[4] = b[4]
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

-- a:invert(matrix2 b)
-- a:invert()
function class.invert(a, b)
  if not b then
    b = a
  end
  local b11 = b[1]
  local b12 = b[2]
  local b21 = b[3]
  local b22 = b[4]
  local d = b11 * b22 - b12 * b21
  if d ~= 0 then
    a[1] = b22 / d
    a[2] = -b12 / d
    a[3] = -b21 / d
    a[4] = b11 / d
    return a
  end
end

-- a:determinant()
function class.determinant(a)
  return a[1] * a[4] - a[2] * a[3]
end

-- a:rot(number angle)
function class.rot(a, angle)
  local c = cos(angle)
  local s = sin(angle)
  a[1] = c
  a[2] = -s
  a[3] = s
  a[4] = c
  return a
end

-- a:mul_normalize(matrix2 b, matrix2 c)
-- a:mul_normalize(matrix2 b)
function class.mul_normalize(a, b, c)
  return normalize(mul(a, b, c))
end

-- a:mul_transpose_both(matrix2 b, matrix2 c)
function class.mul_transpose_both(a, b, c)
  local b11 = b[1]
  local b12 = b[3]
  local b21 = b[2]
  local b22 = b[4]

  local c11 = c[1]
  local c12 = c[3]
  local c21 = c[2]
  local c22 = c[4]

  a[1] = b11 * c11 + b12 * c21
  a[2] = b11 * c12 + b12 * c22
  a[3] = b21 * c11 + b22 * c21
  a[4] = b21 * c12 + b22 * c22
  return a
end

-- a:mul_transpose_left(matrix2 b, matrix2 c)
function class.mul_transpose_left(a, b, c)
  local b11 = b[1]
  local b12 = b[3]
  local b21 = b[2]
  local b22 = b[4]

  local c11 = c[1]
  local c12 = c[2]
  local c21 = c[3]
  local c22 = c[4]

  a[1] = b11 * c11 + b12 * c21
  a[2] = b11 * c12 + b12 * c22
  a[3] = b21 * c11 + b22 * c21
  a[4] = b21 * c12 + b22 * c22
  return a
end

-- a:equals(matrix2 b)
function class.equals(a, b)
  return a and b
      and a[1] == b[1] and a[2] == b[2]
      and a[3] == b[3] and a[4] == b[4]
end

-- a:epsilon_equals(matrix2 b, number epsilon)
function class.epsilon_equals(a, b, epsilon)
  if a and b then
    local m11 = a[1] - b[1]
    local m12 = a[2] - b[2]
    local m21 = a[3] - b[3]
    local m22 = a[4] - b[4]

    if m11 < 0 then m11 = -m11 end
    if m12 < 0 then m12 = -m12 end
    if m21 < 0 then m21 = -m21 end
    if m22 < 0 then m22 = -m22 end

    return m11 <= epsilon and m12 <= epsilon
        and m21 <= epsilon and m22 <= epsilon
  else
    return false
  end
end

-- a:set_zero()
function class.set_zero(a)
  a[1] = 0
  a[2] = 0
  a[3] = 0
  a[4] = 0
  return a
end

-- a:negate(matrix2 b)
-- a:negate()
function class.negate(a, b)
  if not b then
    b = a
  end
  a[1] = -b[1]
  a[2] = -b[2]
  a[3] = -b[3]
  a[4] = -b[4]
  return a
end

-- a:transform(tuple2 b)
function class.transform(a, b, c)
  if not c then
    c = b
  end
  local x = b[1]
  local y = b[2]
  c[1] = a[1] * x + a[2] * y
  c[2] = a[3] * x + a[4] * y
  return c
end

-- a:get_rotation()
function class.get_rotation(a)
  return atan2(a[3] - a[2], a[1] + a[4])
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

-- class(number b, number m12, ...)
-- class(matrix2 b)
-- class()
return setmetatable(class, {
  __call = function (_, ...)
    return setmetatable(class.set({}, ...), metatable)
  end;
})
