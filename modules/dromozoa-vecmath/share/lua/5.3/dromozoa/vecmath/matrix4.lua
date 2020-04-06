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

local matrix3 = require "dromozoa.vecmath.matrix3"
local quat4 = require "dromozoa.vecmath.quat4"
local svd3 = require "dromozoa.vecmath.svd3"

local error = error
local rawget = rawget
local rawset = rawset
local setmetatable = setmetatable
local type = type
local cos = math.cos
local sin = math.sin
local format = string.format

-- a:to_string()
local function to_string(a)
  return format("%.17g, %.17g, %.17g, %.17g\n%.17g, %.17g, %.17g, %.17g\n%.17g, %.17g, %.17g, %.17g\n%.17g, %.17g, %.17g, %.17g\n",
      a[ 1], a[ 2], a[ 3], a[ 4],
      a[ 5], a[ 6], a[ 7], a[ 8],
      a[ 9], a[10], a[11], a[12],
      a[13], a[14], a[15], a[16])
end

-- a:set_axis_angle4(axis_angle4 b)
local function set_axis_angle4(a, b)
  local m = matrix3.set_axis_angle4({}, b)
  a[ 1] = m[1]
  a[ 2] = m[2]
  a[ 3] = m[3]
  a[ 4] = 0
  a[ 5] = m[4]
  a[ 6] = m[5]
  a[ 7] = m[6]
  a[ 8] = 0
  a[ 9] = m[7]
  a[10] = m[8]
  a[11] = m[9]
  a[12] = 0
  a[13] = 0
  a[14] = 0
  a[15] = 0
  a[16] = 1
  return a
end

-- a:set_quat4(quat4 b)
local function set_quat4(a, b)
  local m = matrix3.set_quat4({}, b)
  a[ 1] = m[1]
  a[ 2] = m[2]
  a[ 3] = m[3]
  a[ 4] = 0
  a[ 5] = m[4]
  a[ 6] = m[5]
  a[ 7] = m[6]
  a[ 8] = 0
  a[ 9] = m[7]
  a[10] = m[8]
  a[11] = m[9]
  a[12] = 0
  a[13] = 0
  a[14] = 0
  a[15] = 0
  a[16] = 1
  return a
end

-- a:transform_point3(point3 b, point3 c)
-- a:transform_point3(point3 b)
local function transform_point3(a, b, c)
  if not c then
    c = b
  end
  local x = b[1]
  local y = b[2]
  local z = b[3]
  c[1] = a[1] * x + a[ 2] * y + a[ 3] * z + a[ 4]
  c[2] = a[5] * x + a[ 6] * y + a[ 7] * z + a[ 8]
  c[3] = a[9] * x + a[10] * y + a[11] * z + a[12]
  return c
end

-- a:transform_vector3(vector3 b, vector3 c)
-- a:transform_vector3(vector3 b)
local function transform_vector3(a, b, c)
  if not c then
    c = b
  end
  local x = b[1]
  local y = b[2]
  local z = b[3]
  c[1] = a[1] * x + a[ 2] * y + a[ 3] * z
  c[2] = a[5] * x + a[ 6] * y + a[ 7] * z
  c[3] = a[9] * x + a[10] * y + a[11] * z
  return c
end

-- a:set_rotation_axis_angle4(axis_angle4 b)
local function set_rotation_axis_angle4(a, b)
  local sx, sy, sz = svd3{ a[1], a[2], a[3], a[5], a[6], a[7], a[9], a[10], a[11] }
  local m = matrix3.set_axis_angle4({}, b)
  a[ 1] = m[1] * sx
  a[ 2] = m[2] * sy
  a[ 3] = m[3] * sz
  a[ 5] = m[4] * sx
  a[ 6] = m[5] * sy
  a[ 7] = m[6] * sz
  a[ 9] = m[7] * sx
  a[10] = m[8] * sy
  a[11] = m[9] * sz
  return a
end

-- a:set_rotation_quat4(quat4 b)
local function set_rotation_quat4(a, b)
  local sx, sy, sz = svd3{ a[1], a[2], a[3], a[5], a[6], a[7], a[9], a[10], a[11] }
  local m = matrix3.set_quat4({}, b)
  a[ 1] = m[1] * sx
  a[ 2] = m[2] * sy
  a[ 3] = m[3] * sz
  a[ 5] = m[4] * sx
  a[ 6] = m[5] * sy
  a[ 7] = m[6] * sz
  a[ 9] = m[7] * sx
  a[10] = m[8] * sy
  a[11] = m[9] * sz
  return a
end

local class = {
  is_matrix4 = true;
  index = {
    1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16,
    m11 =  1, m12 =  2, m13 =  3, m14 =  4,
    m21 =  5, m22 =  6, m23 =  7, m24 =  8,
    m31 =  9, m32 = 10, m33 = 11, m34 = 12,
    m41 = 13, m42 = 14, m43 = 15, m44 = 16,
  };
  to_string = to_string;
  set_axis_angle4 = set_axis_angle4;
  set_quat4 = set_quat4;
  transform_point3 = transform_point3;
  transform_vector3 = transform_vector3;
  set_rotation_axis_angle4 = set_rotation_axis_angle4;
  set_rotation_quat4 = set_rotation_quat4;
}
local metatable = { __tostring = to_string }

-- a:set_identity()
function class.set_identity(a)
  a[ 1] = 1
  a[ 2] = 0
  a[ 3] = 0
  a[ 4] = 0
  a[ 5] = 0
  a[ 6] = 1
  a[ 7] = 0
  a[ 8] = 0
  a[ 9] = 0
  a[10] = 0
  a[11] = 1
  a[12] = 0
  a[13] = 0
  a[14] = 0
  a[15] = 0
  a[16] = 1
  return a
end

-- a:get(matrix3 b, vector3 c)
-- a:get(vector3 b)
-- a:get(quat4 b)
-- a:get(matrix3 b)
function class.get(a, b, c)
  if c then
    local u = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }
    local v = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }
    local s = svd3({ a[1], a[2], a[3], a[5], a[6], a[7], a[9], a[10], a[11] }, u, v)
    matrix3.mul_transpose_right(b, u, v)
    c[1] = a[4]
    c[2] = a[8]
    c[3] = a[12]
    return s, b, c
  else
    local n = #b
    if n == 3 then
      b[1] = a[4]
      b[2] = a[8]
      b[3] = a[12]
      return b
    elseif n == 4 then
      return quat4.set(b, matrix3.normalize{ a[1], a[2], a[3], a[5], a[6], a[7], a[9], a[10], a[11] })
    else
      return matrix3.normalize(matrix3.set(b, a[1], a[2], a[3], a[5], a[6], a[7], a[9], a[10], a[11]))
    end
  end
end

-- a:get_rotation_scale(matrix3 b)
function class.get_rotation_scale(a, b)
  b[1] = a[ 1]
  b[2] = a[ 2]
  b[3] = a[ 3]
  b[4] = a[ 5]
  b[5] = a[ 6]
  b[6] = a[ 7]
  b[7] = a[ 9]
  b[8] = a[10]
  b[9] = a[11]
  return b
end

-- a:get_scale()
function class.get_scale(a)
  return svd3{ a[1], a[2], a[3], a[5], a[6], a[7], a[9], a[10], a[11] }
end

-- a:set_rotation_scale(matrix3 b)
function class.set_rotation_scale(a, b)
  a[ 1] = b[1]
  a[ 2] = b[2]
  a[ 3] = b[3]
  a[ 5] = b[4]
  a[ 6] = b[5]
  a[ 7] = b[6]
  a[ 9] = b[7]
  a[10] = b[8]
  a[11] = b[9]
  return a
end

-- a:set_scale(number b)
function class.set_scale(a, b)
  local m = matrix3.set_scale({ a[1], a[2], a[3], a[5], a[6], a[7], a[9], a[10], a[11] }, b)
  a[ 1] = m[1]
  a[ 2] = m[2]
  a[ 3] = m[3]
  a[ 5] = m[4]
  a[ 6] = m[5]
  a[ 7] = m[6]
  a[ 9] = m[7]
  a[10] = m[8]
  a[11] = m[9]
  return a
end

-- a:add(number b, matrix4 c)
-- a:add(matrix4 b, matrix4 c)
-- a:add(number b)
-- a:add(matrix4 b)
function class.add(a, b, c)
  if type(b) == "number" then
    if not c then
      c = a
    end
    a[ 1] = b + c[ 1]
    a[ 2] = b + c[ 2]
    a[ 3] = b + c[ 3]
    a[ 4] = b + c[ 4]
    a[ 5] = b + c[ 5]
    a[ 6] = b + c[ 6]
    a[ 7] = b + c[ 7]
    a[ 8] = b + c[ 8]
    a[ 9] = b + c[ 9]
    a[10] = b + c[10]
    a[11] = b + c[11]
    a[12] = b + c[12]
    a[13] = b + c[13]
    a[14] = b + c[14]
    a[15] = b + c[15]
    a[16] = b + c[16]
    return a
  else
    if not c then
      c = b
      b = a
    end
    a[ 1] = b[ 1] + c[ 1]
    a[ 2] = b[ 2] + c[ 2]
    a[ 3] = b[ 3] + c[ 3]
    a[ 4] = b[ 4] + c[ 4]
    a[ 5] = b[ 5] + c[ 5]
    a[ 6] = b[ 6] + c[ 6]
    a[ 7] = b[ 7] + c[ 7]
    a[ 8] = b[ 8] + c[ 8]
    a[ 9] = b[ 9] + c[ 9]
    a[10] = b[10] + c[10]
    a[11] = b[11] + c[11]
    a[12] = b[12] + c[12]
    a[13] = b[13] + c[13]
    a[14] = b[14] + c[14]
    a[15] = b[15] + c[15]
    a[16] = b[16] + c[16]
    return a
  end
end

-- a:sub(matrix4 b, matrix4 c)
-- a:sub(matrix4 b)
function class.sub(a, b, c)
  if not c then
    c = b
    b = a
  end
  a[ 1] = b[ 1] - c[ 1]
  a[ 2] = b[ 2] - c[ 2]
  a[ 3] = b[ 3] - c[ 3]
  a[ 4] = b[ 4] - c[ 4]
  a[ 5] = b[ 5] - c[ 5]
  a[ 6] = b[ 6] - c[ 6]
  a[ 7] = b[ 7] - c[ 7]
  a[ 8] = b[ 8] - c[ 8]
  a[ 9] = b[ 9] - c[ 9]
  a[10] = b[10] - c[10]
  a[11] = b[11] - c[11]
  a[12] = b[12] - c[12]
  a[13] = b[13] - c[13]
  a[14] = b[14] - c[14]
  a[15] = b[15] - c[15]
  a[16] = b[16] - c[16]
  return a
end

-- a:transpose(matrix4 b)
-- a:transpose()
function class.transpose(a, b)
  if b then
    a[2], a[5] = b[5], b[2]
    a[3], a[9] = b[9], b[3]
    a[4], a[13] = b[13], b[4]
    a[7], a[10] = b[10], b[7]
    a[8], a[14] = b[14], b[8]
    a[12], a[15] = b[15], b[12]
    a[1] = b[1]
    a[6] = b[6]
    a[11] = b[11]
    a[16] = b[16]
    return a
  else
    a[2], a[5] = a[5], a[2]
    a[3], a[9] = a[9], a[3]
    a[4], a[13] = a[13], a[4]
    a[7], a[10] = a[10], a[7]
    a[8], a[14] = a[14], a[8]
    a[12], a[15] = a[15], a[12]
    return a
  end
end

-- a:set(number b, number c, number d, number m14, ...)
-- a:set(quat4 b, vector3 c, number d)
-- a:set(matrix3 b, vector3 c, number d)
-- a:set(number b, vector3 c)
-- a:set(vector3 b, number c)
-- a:set(number b)
-- a:set(vector3 b)
-- a:set(axis_angle4 b)
-- a:set(quat4 b)
-- a:set(matrix3 b)
-- a:set(matrix4 b)
-- a:set()
function class.set(a, b, c, d, m14, m21, m22, m23, m24, m31, m32, m33, m34, m41, m42, m43, m44)
  if b then
    if c then
      if d then
        if m14 then
          a[ 1] = b
          a[ 2] = c
          a[ 3] = d
          a[ 4] = m14
          a[ 5] = m21
          a[ 6] = m22
          a[ 7] = m23
          a[ 8] = m24
          a[ 9] = m31
          a[10] = m32
          a[11] = m33
          a[12] = m34
          a[13] = m41
          a[14] = m42
          a[15] = m43
          a[16] = m44
          return a
        else
          if #b == 4 then
            b = matrix3.set_quat4({}, b)
          end
          a[ 1] = b[1] * d
          a[ 2] = b[2] * d
          a[ 3] = b[3] * d
          a[ 4] = c[1]
          a[ 5] = b[4] * d
          a[ 6] = b[5] * d
          a[ 7] = b[6] * d
          a[ 8] = c[2]
          a[ 9] = b[7] * d
          a[10] = b[8] * d
          a[11] = b[9] * d
          a[12] = c[3]
          a[13] = 0
          a[14] = 0
          a[15] = 0
          a[16] = 1
          return a
        end
      else
        if type(b) == "number" then
          a[ 1] = b
          a[ 2] = 0
          a[ 3] = 0
          a[ 4] = c[1]
          a[ 5] = 0
          a[ 6] = b
          a[ 7] = 0
          a[ 8] = c[2]
          a[ 9] = 0
          a[10] = 0
          a[11] = b
          a[12] = c[3]
          a[13] = 0
          a[14] = 0
          a[15] = 0
          a[16] = 1
          return a
        else
          a[ 1] = c
          a[ 2] = 0
          a[ 3] = 0
          a[ 4] = b[1] * c
          a[ 5] = 0
          a[ 6] = c
          a[ 7] = 0
          a[ 8] = b[2] * c
          a[ 9] = 0
          a[10] = 0
          a[11] = c
          a[12] = b[3] * c
          a[13] = 0
          a[14] = 0
          a[15] = 0
          a[16] = 1
          return a
        end
      end
    else
      if type(b) == "number" then
        a[ 1] = b
        a[ 2] = 0
        a[ 3] = 0
        a[ 4] = 0
        a[ 5] = 0
        a[ 6] = b
        a[ 7] = 0
        a[ 8] = 0
        a[ 9] = 0
        a[10] = 0
        a[11] = b
        a[12] = 0
        a[13] = 0
        a[14] = 0
        a[15] = 0
        a[16] = 1
        return a
      else
        local n = #b
        if n == 3 then
          a[ 1] = 1
          a[ 2] = 0
          a[ 3] = 0
          a[ 4] = b[1]
          a[ 5] = 0
          a[ 6] = 1
          a[ 7] = 0
          a[ 8] = b[2]
          a[ 9] = 0
          a[10] = 0
          a[11] = 1
          a[12] = b[3]
          a[13] = 0
          a[14] = 0
          a[15] = 0
          a[16] = 1
          return a
        elseif n == 4 then
          if b.is_axis_angle4 then
            return set_axis_angle4(a, b)
          elseif b.is_quat4 then
            return set_quat4(a, b)
          else
            error "bad argument #2 (axis_angle4 or quat4 expected)"
          end
        elseif n == 9 then
          a[ 1] = b[1]
          a[ 2] = b[2]
          a[ 3] = b[3]
          a[ 4] = 0
          a[ 5] = b[4]
          a[ 6] = b[5]
          a[ 7] = b[6]
          a[ 8] = 0
          a[ 9] = b[7]
          a[10] = b[8]
          a[11] = b[9]
          a[12] = 0
          a[13] = 0
          a[14] = 0
          a[15] = 0
          a[16] = 1
          return a
        else
          a[ 1] = b[ 1]
          a[ 2] = b[ 2]
          a[ 3] = b[ 3]
          a[ 4] = b[ 4]
          a[ 5] = b[ 5]
          a[ 6] = b[ 6]
          a[ 7] = b[ 7]
          a[ 8] = b[ 8]
          a[ 9] = b[ 9]
          a[10] = b[10]
          a[11] = b[11]
          a[12] = b[12]
          a[13] = b[13]
          a[14] = b[14]
          a[15] = b[15]
          a[16] = b[16]
          return a
        end
      end
    end
  else
    a[ 1] = 0
    a[ 2] = 0
    a[ 3] = 0
    a[ 4] = 0
    a[ 5] = 0
    a[ 6] = 0
    a[ 7] = 0
    a[ 8] = 0
    a[ 9] = 0
    a[10] = 0
    a[11] = 0
    a[12] = 0
    a[13] = 0
    a[14] = 0
    a[15] = 0
    a[16] = 0
    return a
  end
end

-- a:invert(matrix4 b)
-- a:invert()
function class.invert(a, b)
  if not b then
    b = a
  end

  local m11 = b[ 1]
  local m12 = b[ 2]
  local m13 = b[ 3]
  local m14 = b[ 4]
  local m21 = b[ 5]
  local m22 = b[ 6]
  local m23 = b[ 7]
  local m24 = b[ 8]
  local m31 = b[ 9]
  local m32 = b[10]
  local m33 = b[11]
  local m34 = b[12]
  local m41 = b[13]
  local m42 = b[14]
  local m43 = b[15]
  local m44 = b[16]

  local n11 = m22 * (m33 * m44 - m34 * m43) + m23 * (m34 * m42 - m32 * m44) + m24 * (m32 * m43 - m33 * m42)
  local n12 = m32 * (m13 * m44 - m14 * m43) + m33 * (m14 * m42 - m12 * m44) + m34 * (m12 * m43 - m13 * m42)
  local n13 = m42 * (m13 * m24 - m14 * m23) + m43 * (m14 * m22 - m12 * m24) + m44 * (m12 * m23 - m13 * m22)
  local n14 = m12 * (m24 * m33 - m23 * m34) + m13 * (m22 * m34 - m24 * m32) + m14 * (m23 * m32 - m22 * m33)
  local d = m11 * n11 + m21 * n12 + m31 * n13 + m41 * n14;

  if d ~= 0 then
    a[ 1] = n11 / d
    a[ 2] = n12 / d
    a[ 3] = n13 / d
    a[ 4] = n14 / d
    a[ 5] = (m23 * (m31 * m44 - m34 * m41) + m24 * (m33 * m41 - m31 * m43) + m21 * (m34 * m43 - m33 * m44)) / d
    a[ 6] = (m33 * (m11 * m44 - m14 * m41) + m34 * (m13 * m41 - m11 * m43) + m31 * (m14 * m43 - m13 * m44)) / d
    a[ 7] = (m43 * (m11 * m24 - m14 * m21) + m44 * (m13 * m21 - m11 * m23) + m41 * (m14 * m23 - m13 * m24)) / d
    a[ 8] = (m13 * (m24 * m31 - m21 * m34) + m14 * (m21 * m33 - m23 * m31) + m11 * (m23 * m34 - m24 * m33)) / d
    a[ 9] = (m24 * (m31 * m42 - m32 * m41) + m21 * (m32 * m44 - m34 * m42) + m22 * (m34 * m41 - m31 * m44)) / d
    a[10] = (m34 * (m11 * m42 - m12 * m41) + m31 * (m12 * m44 - m14 * m42) + m32 * (m14 * m41 - m11 * m44)) / d
    a[11] = (m44 * (m11 * m22 - m12 * m21) + m41 * (m12 * m24 - m14 * m22) + m42 * (m14 * m21 - m11 * m24)) / d
    a[12] = (m14 * (m22 * m31 - m21 * m32) + m11 * (m24 * m32 - m22 * m34) + m12 * (m21 * m34 - m24 * m31)) / d
    a[13] = (m21 * (m33 * m42 - m32 * m43) + m22 * (m31 * m43 - m33 * m41) + m23 * (m32 * m41 - m31 * m42)) / d
    a[14] = (m31 * (m13 * m42 - m12 * m43) + m32 * (m11 * m43 - m13 * m41) + m33 * (m12 * m41 - m11 * m42)) / d
    a[15] = (m41 * (m13 * m22 - m12 * m23) + m42 * (m11 * m23 - m13 * m21) + m43 * (m12 * m21 - m11 * m22)) / d
    a[16] = (m11 * (m22 * m33 - m23 * m32) + m12 * (m23 * m31 - m21 * m33) + m13 * (m21 * m32 - m22 * m31)) / d
    return a
  end
end

-- a:determinant()
function class.determinant(a)
  local m11 = a[ 1]
  local m12 = a[ 2]
  local m13 = a[ 3]
  local m14 = a[ 4]
  local m21 = a[ 5]
  local m22 = a[ 6]
  local m23 = a[ 7]
  local m24 = a[ 8]
  local m31 = a[ 9]
  local m32 = a[10]
  local m33 = a[11]
  local m34 = a[12]
  local m41 = a[13]
  local m42 = a[14]
  local m43 = a[15]
  local m44 = a[16]

  return (m11 * m22 - m12 * m21) * (m33 * m44 - m34 * m43)
      - (m11 * m23 - m13 * m21) * (m32 * m44 - m34 * m42)
      + (m11 * m24 - m14 * m21) * (m32 * m43 - m33 * m42)
      + (m12 * m23 - m13 * m22) * (m31 * m44 - m34 * m41)
      - (m12 * m24 - m14 * m22) * (m31 * m43 - m33 * m41)
      + (m13 * m24 - m14 * m23) * (m31 * m42 - m32 * m41)
end

-- a:set_translation(vector3 b)
function class.set_translation(a, b)
  a[ 4] = b[1]
  a[ 8] = b[2]
  a[12] = b[3]
  return a
end

-- a:rot_x(number angle)
function class.rot_x(a, angle)
  local c = cos(angle)
  local s = sin(angle)
  a[ 1] = 1
  a[ 2] = 0
  a[ 3] = 0
  a[ 4] = 0
  a[ 5] = 0
  a[ 6] = c
  a[ 7] = -s
  a[ 8] = 0
  a[ 9] = 0
  a[10] = s
  a[11] = c
  a[12] = 0
  a[13] = 0
  a[14] = 0
  a[15] = 0
  a[16] = 1
  return a
end

-- a:rot_y(number angle)
function class.rot_y(a, angle)
  local c = cos(angle)
  local s = sin(angle)
  a[ 1] = c
  a[ 2] = 0
  a[ 3] = s
  a[ 4] = 0
  a[ 5] = 0
  a[ 6] = 1
  a[ 7] = 0
  a[ 8] = 0
  a[ 9] = -s
  a[10] = 0
  a[11] = c
  a[12] = 0
  a[13] = 0
  a[14] = 0
  a[15] = 0
  a[16] = 1
  return a
end

-- a:rot_z(number angle)
function class.rot_z(a, angle)
  local c = cos(angle)
  local s = sin(angle)
  a[ 1] = c
  a[ 2] = -s
  a[ 3] = 0
  a[ 4] = 0
  a[ 5] = s
  a[ 6] = c
  a[ 7] = 0
  a[ 8] = 0
  a[ 9] = 0
  a[10] = 0
  a[11] = 1
  a[12] = 0
  a[13] = 0
  a[14] = 0
  a[15] = 0
  a[16] = 1
  return a
end

-- a:mul(number b, matrix4 c)
-- a:mul(matrix4 b, matrix4 c)
-- a:mul(number b)
-- a:mul(matrix4 b)
function class.mul(a, b, c)
  if type(b) == "number" then
    if not c then
      c = a
    end
    a[ 1] = b * c[ 1]
    a[ 2] = b * c[ 2]
    a[ 3] = b * c[ 3]
    a[ 4] = b * c[ 4]
    a[ 5] = b * c[ 5]
    a[ 6] = b * c[ 6]
    a[ 7] = b * c[ 7]
    a[ 8] = b * c[ 8]
    a[ 9] = b * c[ 9]
    a[10] = b * c[10]
    a[11] = b * c[11]
    a[12] = b * c[12]
    a[13] = b * c[13]
    a[14] = b * c[14]
    a[15] = b * c[15]
    a[16] = b * c[16]
    return a
  else
    if not c then
      c = b
      b = a
    end

    local b11 = b[ 1]
    local b12 = b[ 2]
    local b13 = b[ 3]
    local b14 = b[ 4]
    local b21 = b[ 5]
    local b22 = b[ 6]
    local b23 = b[ 7]
    local b24 = b[ 8]
    local b31 = b[ 9]
    local b32 = b[10]
    local b33 = b[11]
    local b34 = b[12]
    local b41 = b[13]
    local b42 = b[14]
    local b43 = b[15]
    local b44 = b[16]

    local c11 = c[ 1]
    local c12 = c[ 2]
    local c13 = c[ 3]
    local c14 = c[ 4]
    local c21 = c[ 5]
    local c22 = c[ 6]
    local c23 = c[ 7]
    local c24 = c[ 8]
    local c31 = c[ 9]
    local c32 = c[10]
    local c33 = c[11]
    local c34 = c[12]
    local c41 = c[13]
    local c42 = c[14]
    local c43 = c[15]
    local c44 = c[16]

    a[ 1] = b11 * c11 + b12 * c21 + b13 * c31 + b14 * c41
    a[ 2] = b11 * c12 + b12 * c22 + b13 * c32 + b14 * c42
    a[ 3] = b11 * c13 + b12 * c23 + b13 * c33 + b14 * c43
    a[ 4] = b11 * c14 + b12 * c24 + b13 * c34 + b14 * c44
    a[ 5] = b21 * c11 + b22 * c21 + b23 * c31 + b24 * c41
    a[ 6] = b21 * c12 + b22 * c22 + b23 * c32 + b24 * c42
    a[ 7] = b21 * c13 + b22 * c23 + b23 * c33 + b24 * c43
    a[ 8] = b21 * c14 + b22 * c24 + b23 * c34 + b24 * c44
    a[ 9] = b31 * c11 + b32 * c21 + b33 * c31 + b34 * c41
    a[10] = b31 * c12 + b32 * c22 + b33 * c32 + b34 * c42
    a[11] = b31 * c13 + b32 * c23 + b33 * c33 + b34 * c43
    a[12] = b31 * c14 + b32 * c24 + b33 * c34 + b34 * c44
    a[13] = b41 * c11 + b42 * c21 + b43 * c31 + b44 * c41
    a[14] = b41 * c12 + b42 * c22 + b43 * c32 + b44 * c42
    a[15] = b41 * c13 + b42 * c23 + b43 * c33 + b44 * c43
    a[16] = b41 * c14 + b42 * c24 + b43 * c34 + b44 * c44
    return a
  end
end

-- a:mul_transpose_both(matrix4 b, matrix4 c)
function class.mul_transpose_both(a, b, c)
  local b11 = b[ 1]
  local b12 = b[ 5]
  local b13 = b[ 9]
  local b14 = b[13]
  local b21 = b[ 2]
  local b22 = b[ 6]
  local b23 = b[10]
  local b24 = b[14]
  local b31 = b[ 3]
  local b32 = b[ 7]
  local b33 = b[11]
  local b34 = b[15]
  local b41 = b[ 4]
  local b42 = b[ 8]
  local b43 = b[12]
  local b44 = b[16]

  local c11 = c[ 1]
  local c12 = c[ 5]
  local c13 = c[ 9]
  local c14 = c[13]
  local c21 = c[ 2]
  local c22 = c[ 6]
  local c23 = c[10]
  local c24 = c[14]
  local c31 = c[ 3]
  local c32 = c[ 7]
  local c33 = c[11]
  local c34 = c[15]
  local c41 = c[ 4]
  local c42 = c[ 8]
  local c43 = c[12]
  local c44 = c[16]

  a[ 1] = b11 * c11 + b12 * c21 + b13 * c31 + b14 * c41
  a[ 2] = b11 * c12 + b12 * c22 + b13 * c32 + b14 * c42
  a[ 3] = b11 * c13 + b12 * c23 + b13 * c33 + b14 * c43
  a[ 4] = b11 * c14 + b12 * c24 + b13 * c34 + b14 * c44
  a[ 5] = b21 * c11 + b22 * c21 + b23 * c31 + b24 * c41
  a[ 6] = b21 * c12 + b22 * c22 + b23 * c32 + b24 * c42
  a[ 7] = b21 * c13 + b22 * c23 + b23 * c33 + b24 * c43
  a[ 8] = b21 * c14 + b22 * c24 + b23 * c34 + b24 * c44
  a[ 9] = b31 * c11 + b32 * c21 + b33 * c31 + b34 * c41
  a[10] = b31 * c12 + b32 * c22 + b33 * c32 + b34 * c42
  a[11] = b31 * c13 + b32 * c23 + b33 * c33 + b34 * c43
  a[12] = b31 * c14 + b32 * c24 + b33 * c34 + b34 * c44
  a[13] = b41 * c11 + b42 * c21 + b43 * c31 + b44 * c41
  a[14] = b41 * c12 + b42 * c22 + b43 * c32 + b44 * c42
  a[15] = b41 * c13 + b42 * c23 + b43 * c33 + b44 * c43
  a[16] = b41 * c14 + b42 * c24 + b43 * c34 + b44 * c44
  return a
end

-- a:mul_transpose_right(matrix4 b, matrix4 c)
function class.mul_transpose_right(a, b, c)
  local b11 = b[ 1]
  local b12 = b[ 2]
  local b13 = b[ 3]
  local b14 = b[ 4]
  local b21 = b[ 5]
  local b22 = b[ 6]
  local b23 = b[ 7]
  local b24 = b[ 8]
  local b31 = b[ 9]
  local b32 = b[10]
  local b33 = b[11]
  local b34 = b[12]
  local b41 = b[13]
  local b42 = b[14]
  local b43 = b[15]
  local b44 = b[16]

  local c11 = c[ 1]
  local c12 = c[ 5]
  local c13 = c[ 9]
  local c14 = c[13]
  local c21 = c[ 2]
  local c22 = c[ 6]
  local c23 = c[10]
  local c24 = c[14]
  local c31 = c[ 3]
  local c32 = c[ 7]
  local c33 = c[11]
  local c34 = c[15]
  local c41 = c[ 4]
  local c42 = c[ 8]
  local c43 = c[12]
  local c44 = c[16]

  a[ 1] = b11 * c11 + b12 * c21 + b13 * c31 + b14 * c41
  a[ 2] = b11 * c12 + b12 * c22 + b13 * c32 + b14 * c42
  a[ 3] = b11 * c13 + b12 * c23 + b13 * c33 + b14 * c43
  a[ 4] = b11 * c14 + b12 * c24 + b13 * c34 + b14 * c44
  a[ 5] = b21 * c11 + b22 * c21 + b23 * c31 + b24 * c41
  a[ 6] = b21 * c12 + b22 * c22 + b23 * c32 + b24 * c42
  a[ 7] = b21 * c13 + b22 * c23 + b23 * c33 + b24 * c43
  a[ 8] = b21 * c14 + b22 * c24 + b23 * c34 + b24 * c44
  a[ 9] = b31 * c11 + b32 * c21 + b33 * c31 + b34 * c41
  a[10] = b31 * c12 + b32 * c22 + b33 * c32 + b34 * c42
  a[11] = b31 * c13 + b32 * c23 + b33 * c33 + b34 * c43
  a[12] = b31 * c14 + b32 * c24 + b33 * c34 + b34 * c44
  a[13] = b41 * c11 + b42 * c21 + b43 * c31 + b44 * c41
  a[14] = b41 * c12 + b42 * c22 + b43 * c32 + b44 * c42
  a[15] = b41 * c13 + b42 * c23 + b43 * c33 + b44 * c43
  a[16] = b41 * c14 + b42 * c24 + b43 * c34 + b44 * c44
  return a
end

-- a:mul_transpose_left(matrix4 b, matrix4 c)
function class.mul_transpose_left(a, b, c)
  local b11 = b[ 1]
  local b12 = b[ 5]
  local b13 = b[ 9]
  local b14 = b[13]
  local b21 = b[ 2]
  local b22 = b[ 6]
  local b23 = b[10]
  local b24 = b[14]
  local b31 = b[ 3]
  local b32 = b[ 7]
  local b33 = b[11]
  local b34 = b[15]
  local b41 = b[ 4]
  local b42 = b[ 8]
  local b43 = b[12]
  local b44 = b[16]

  local c11 = c[ 1]
  local c12 = c[ 2]
  local c13 = c[ 3]
  local c14 = c[ 4]
  local c21 = c[ 5]
  local c22 = c[ 6]
  local c23 = c[ 7]
  local c24 = c[ 8]
  local c31 = c[ 9]
  local c32 = c[10]
  local c33 = c[11]
  local c34 = c[12]
  local c41 = c[13]
  local c42 = c[14]
  local c43 = c[15]
  local c44 = c[16]

  a[ 1] = b11 * c11 + b12 * c21 + b13 * c31 + b14 * c41
  a[ 2] = b11 * c12 + b12 * c22 + b13 * c32 + b14 * c42
  a[ 3] = b11 * c13 + b12 * c23 + b13 * c33 + b14 * c43
  a[ 4] = b11 * c14 + b12 * c24 + b13 * c34 + b14 * c44
  a[ 5] = b21 * c11 + b22 * c21 + b23 * c31 + b24 * c41
  a[ 6] = b21 * c12 + b22 * c22 + b23 * c32 + b24 * c42
  a[ 7] = b21 * c13 + b22 * c23 + b23 * c33 + b24 * c43
  a[ 8] = b21 * c14 + b22 * c24 + b23 * c34 + b24 * c44
  a[ 9] = b31 * c11 + b32 * c21 + b33 * c31 + b34 * c41
  a[10] = b31 * c12 + b32 * c22 + b33 * c32 + b34 * c42
  a[11] = b31 * c13 + b32 * c23 + b33 * c33 + b34 * c43
  a[12] = b31 * c14 + b32 * c24 + b33 * c34 + b34 * c44
  a[13] = b41 * c11 + b42 * c21 + b43 * c31 + b44 * c41
  a[14] = b41 * c12 + b42 * c22 + b43 * c32 + b44 * c42
  a[15] = b41 * c13 + b42 * c23 + b43 * c33 + b44 * c43
  a[16] = b41 * c14 + b42 * c24 + b43 * c34 + b44 * c44
  return a
end

-- a:equals(matrix4 b)
function class.equals(a, b)
  return a and b
      and a[ 1] == b[ 1] and a[ 2] == b[ 2] and a[ 3] == b[ 3] and a[ 4] == b[ 4]
      and a[ 5] == b[ 5] and a[ 6] == b[ 6] and a[ 7] == b[ 7] and a[ 8] == b[ 8]
      and a[ 9] == b[ 9] and a[10] == b[10] and a[11] == b[11] and a[12] == b[12]
      and a[13] == b[13] and a[14] == b[14] and a[15] == b[15] and a[16] == b[16]
end

-- a:epsilon_equals(matrix4 b, number epsilon)
function class.epsilon_equals(a, b, epsilon)
  if a and b then
    local m11 = a[ 1] - b[ 1]
    local m12 = a[ 2] - b[ 2]
    local m13 = a[ 3] - b[ 3]
    local m14 = a[ 4] - b[ 4]
    local m21 = a[ 5] - b[ 5]
    local m22 = a[ 6] - b[ 6]
    local m23 = a[ 7] - b[ 7]
    local m24 = a[ 8] - b[ 8]
    local m31 = a[ 9] - b[ 9]
    local m32 = a[10] - b[10]
    local m33 = a[11] - b[11]
    local m34 = a[12] - b[12]
    local m41 = a[13] - b[13]
    local m42 = a[14] - b[14]
    local m43 = a[15] - b[15]
    local m44 = a[16] - b[16]

    if m11 < 0 then m11 = -m11 end
    if m12 < 0 then m12 = -m12 end
    if m13 < 0 then m13 = -m13 end
    if m14 < 0 then m14 = -m14 end
    if m21 < 0 then m21 = -m21 end
    if m22 < 0 then m22 = -m22 end
    if m23 < 0 then m23 = -m23 end
    if m24 < 0 then m24 = -m24 end
    if m31 < 0 then m31 = -m31 end
    if m32 < 0 then m32 = -m32 end
    if m33 < 0 then m33 = -m33 end
    if m34 < 0 then m34 = -m34 end
    if m41 < 0 then m41 = -m41 end
    if m42 < 0 then m42 = -m42 end
    if m43 < 0 then m43 = -m43 end
    if m44 < 0 then m44 = -m44 end

    return m11 <= epsilon and m12 <= epsilon and m13 <= epsilon and m14 <= epsilon
        and m21 <= epsilon and m22 <= epsilon and m23 <= epsilon and m24 <= epsilon
        and m31 <= epsilon and m32 <= epsilon and m33 <= epsilon and m34 <= epsilon
        and m41 <= epsilon and m42 <= epsilon and m43 <= epsilon and m44 <= epsilon
  else
    return false
  end
end

-- a:transform(point3 b, point3 c)
-- a:transform(vector3 b, vector3 c)
-- a:transform(tuple4 b, tuple4 c)
-- a:transform(point3 b)
-- a:transform(vector3 b)
-- a:transform(tuple4 b)
function class.transform(a, b, c)
  if #b == 3 then
    if b.is_point3 then
      return transform_point3(a, b, c)
    elseif b.is_vector3 then
      return transform_vector3(a, b, c)
    else
      error "bad argument #2 (point3 or vector3 expected)"
    end
  else
    if not c then
      c = b
    end
    local x = b[1]
    local y = b[2]
    local z = b[3]
    local w = b[4]
    c[1] = a[ 1] * x + a[ 2] * y + a[ 3] * z + a[ 4] * w
    c[2] = a[ 5] * x + a[ 6] * y + a[ 7] * z + a[ 8] * w
    c[3] = a[ 9] * x + a[10] * y + a[11] * z + a[12] * w
    c[4] = a[13] * x + a[14] * y + a[15] * z + a[16] * w
    return c
  end
end

-- a:set_rotation(axis_angle4 b)
-- a:set_rotation(quat4 b)
-- a:set_rotation(matrix3 b)
function class.set_rotation(a, b)
  if #b == 4 then
    if b.is_axis_angle4 then
      return set_rotation_axis_angle4(a, b)
    elseif b.is_quat4 then
      return set_rotation_quat4(a, b)
    else
      error "bad argument #2 (axis_angle4 or quat4 expected)"
    end
  else
    local sx, sy, sz = svd3{ a[1], a[2], a[3], a[5], a[6], a[7], a[9], a[10], a[11] }
    a[ 1] = b[1] * sx
    a[ 2] = b[2] * sy
    a[ 3] = b[3] * sz
    a[ 5] = b[4] * sx
    a[ 6] = b[5] * sy
    a[ 7] = b[6] * sz
    a[ 9] = b[7] * sx
    a[10] = b[8] * sy
    a[11] = b[9] * sz
    return a
  end
end

-- a:set_zero()
function class.set_zero(a)
  a[ 1] = 0
  a[ 2] = 0
  a[ 3] = 0
  a[ 4] = 0
  a[ 5] = 0
  a[ 6] = 0
  a[ 7] = 0
  a[ 8] = 0
  a[ 9] = 0
  a[10] = 0
  a[11] = 0
  a[12] = 0
  a[13] = 0
  a[14] = 0
  a[15] = 0
  a[16] = 0
  return a
end

-- a:negate(matrix4 b)
-- a:negate()
function class.negate(a, b)
  if not b then
    b = a
  end
  a[ 1] = -b[ 1]
  a[ 2] = -b[ 2]
  a[ 3] = -b[ 3]
  a[ 4] = -b[ 4]
  a[ 5] = -b[ 5]
  a[ 6] = -b[ 6]
  a[ 7] = -b[ 7]
  a[ 8] = -b[ 8]
  a[ 9] = -b[ 9]
  a[10] = -b[10]
  a[11] = -b[11]
  a[12] = -b[12]
  a[13] = -b[13]
  a[14] = -b[14]
  a[15] = -b[15]
  a[16] = -b[16]
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

-- class(number b, number c, number d, number m14, ...)
-- class(quat4 b, vector3 c, number d)
-- class(matrix3 b, vector3 c, number d)
-- class(matrix4 b)
-- class()
return setmetatable(class, {
  __call = function (_, ...)
    return setmetatable(class.set({}, ...), metatable)
  end;
})
