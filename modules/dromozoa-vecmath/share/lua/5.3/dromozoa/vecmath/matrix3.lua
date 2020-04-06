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

local matrix2 = require "dromozoa.vecmath.matrix2"
local svd2 = require "dromozoa.vecmath.svd2"
local svd3 = require "dromozoa.vecmath.svd3"

local error = error
local rawget = rawget
local rawset = rawset
local setmetatable = setmetatable
local type = type
local cos = math.cos
local sin = math.sin
local sqrt = math.sqrt
local format = string.format

-- a:to_string()
local function to_string(a)
  return format("%.17g, %.17g, %.17g\n%.17g, %.17g, %.17g\n%.17g, %.17g, %.17g\n",
      a[1], a[2], a[3],
      a[4], a[5], a[6],
      a[7], a[8], a[9])
end

-- a:mul(number b, matrix3 c)
-- a:mul(matrix3 b, matrix3 c)
-- a:mul(number b)
-- a:mul(matrix3 b)
local function mul(a, b, c)
  if type(b) == "number" then
    if not c then
      c = a
    end
    a[1] = b * c[1]
    a[2] = b * c[2]
    a[3] = b * c[3]
    a[4] = b * c[4]
    a[5] = b * c[5]
    a[6] = b * c[6]
    a[7] = b * c[7]
    a[8] = b * c[8]
    a[9] = b * c[9]
    return a
  else
    if not c then
      c = b
      b = a
    end
    local b11 = b[1]
    local b12 = b[2]
    local b13 = b[3]
    local b21 = b[4]
    local b22 = b[5]
    local b23 = b[6]
    local b31 = b[7]
    local b32 = b[8]
    local b33 = b[9]

    local c11 = c[1]
    local c12 = c[2]
    local c13 = c[3]
    local c21 = c[4]
    local c22 = c[5]
    local c23 = c[6]
    local c31 = c[7]
    local c32 = c[8]
    local c33 = c[9]

    a[1] = b11 * c11 + b12 * c21 + b13 * c31
    a[2] = b11 * c12 + b12 * c22 + b13 * c32
    a[3] = b11 * c13 + b12 * c23 + b13 * c33
    a[4] = b21 * c11 + b22 * c21 + b23 * c31
    a[5] = b21 * c12 + b22 * c22 + b23 * c32
    a[6] = b21 * c13 + b22 * c23 + b23 * c33
    a[7] = b31 * c11 + b32 * c21 + b33 * c31
    a[8] = b31 * c12 + b32 * c22 + b33 * c32
    a[9] = b31 * c13 + b32 * c23 + b33 * c33
    return a
  end
end

-- a:mul_transpose_right(matrix3 b, matrix3 c)
local function mul_transpose_right(a, b, c)
  local b11 = b[1]
  local b12 = b[2]
  local b13 = b[3]
  local b21 = b[4]
  local b22 = b[5]
  local b23 = b[6]
  local b31 = b[7]
  local b32 = b[8]
  local b33 = b[9]

  local c11 = c[1]
  local c12 = c[4]
  local c13 = c[7]
  local c21 = c[2]
  local c22 = c[5]
  local c23 = c[8]
  local c31 = c[3]
  local c32 = c[6]
  local c33 = c[9]

  a[1] = b11 * c11 + b12 * c21 + b13 * c31
  a[2] = b11 * c12 + b12 * c22 + b13 * c32
  a[3] = b11 * c13 + b12 * c23 + b13 * c33
  a[4] = b21 * c11 + b22 * c21 + b23 * c31
  a[5] = b21 * c12 + b22 * c22 + b23 * c32
  a[6] = b21 * c13 + b22 * c23 + b23 * c33
  a[7] = b31 * c11 + b32 * c21 + b33 * c31
  a[8] = b31 * c12 + b32 * c22 + b33 * c32
  a[9] = b31 * c13 + b32 * c23 + b33 * c33
  return a
end

-- a:normalize(matrix3 b)
-- a:normalize()
local function normalize(a, b)
  if not b then
    b = a
  end
  local u = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }
  local v = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }
  svd3({ b[1], b[2], b[3], b[4], b[5], b[6], b[7], b[8], b[9] }, u, v)
  return mul_transpose_right(a, u, v)
end

-- a:set_axis_angle4(axis_angle4 b)
local function set_axis_angle4(a, b)
  local x = b[1]
  local y = b[2]
  local z = b[3]
  local angle = b[4]
  local d = sqrt(x * x + y * y + z * z)
  x = x / d
  y = y / d
  z = z / d

  local c = cos(angle)
  local s = sin(angle)
  local v = (1 - c)
  local xy = x * y * v
  local yz = y * z * v
  local zx = z * x * v
  local xs = x * s
  local ys = y * s
  local zs = z * s

  a[1] = c + x * x * v
  a[2] = xy - zs
  a[3] = zx + ys
  a[4] = xy + zs
  a[5] = c + y * y * v
  a[6] = yz - xs
  a[7] = zx - ys
  a[8] = yz + xs
  a[9] = c + z * z * v
  return a
end

-- a:set_quat4(quat4 b)
local function set_quat4(a, b)
  local x = b[1]
  local y = b[2]
  local z = b[3]
  local w = b[4]

  local d = (x * x + y * y + z * z + w * w) * 0.5
  local xd = x / d
  local yd = y / d
  local zd = z / d
  local wd = w / d
  local xx = x * xd
  local yy = y * yd
  local zz = z * zd
  local xy = x * yd
  local yz = y * zd
  local zx = z * xd
  local wx = w * xd
  local wy = w * yd
  local wz = w * zd
  local ww = w * wd

  a[1] = 1 - yy - zz
  a[2] = xy - wz
  a[3] = zx + wy
  a[4] = xy + wz
  a[5] = 1 - xx - zz
  a[6] = yz - wx
  a[7] = zx - wy
  a[8] = yz + wx
  a[9] = 1 - xx - yy
  return a
end

-- a:set_matrix2(matrix2 b) [EX]
local function set_matrix2(a, b)
  a[1] = b[1]
  a[2] = b[2]
  a[3] = 0
  a[4] = b[3]
  a[5] = b[4]
  a[6] = 0
  a[7] = 0
  a[8] = 0
  a[9] = 1
  return a
end

-- a:transform_point2(point2 b, point2 c) [EX]
-- a:transform_point2(point2 b) [EX]
local function transform_point2(a, b, c)
  if not c then
    c = b
  end
  local x = b[1]
  local y = b[2]
  c[1] = a[1] * x + a[2] * y + a[3]
  c[2] = a[4] * x + a[5] * y + a[6]
  return c
end

-- a:transform_vector2(vector2 b, vector2 c) [EX]
-- a:transform_vector2(vector2 b) [EX]
local function transform_vector2(a, b, c)
  if not c then
    c = b
  end
  local x = b[1]
  local y = b[2]
  c[1] = a[1] * x + a[2] * y
  c[2] = a[4] * x + a[5] * y
  return c
end

local class = {
  is_matrix3 = true;
  index = {
    1, 2, 3, 4, 5, 6, 7, 8, 9,
    m11 = 1, m12 = 2, m13 = 3,
    m21 = 4, m22 = 5, m23 = 6,
    m31 = 7, m32 = 8, m33 = 9,
  };
  to_string = to_string;
  mul = mul;
  mul_transpose_right = mul_transpose_right;
  normalize = normalize;
  set_axis_angle4 = set_axis_angle4;
  set_quat4 = set_quat4;
  transform_point2 = transform_point2;
  transform_vector2 = transform_vector2;
}
local metatable = { __tostring = to_string }

-- a:set_identity()
function class.set_identity(a)
  a[1] = 1
  a[2] = 0
  a[3] = 0
  a[4] = 0
  a[5] = 1
  a[6] = 0
  a[7] = 0
  a[8] = 0
  a[9] = 1
  return a
end

-- a:set_scale(number scale)
function class.set_scale(a, scale)
  normalize(a)
  a[1] = a[1] * scale
  a[2] = a[2] * scale
  a[3] = a[3] * scale
  a[4] = a[4] * scale
  a[5] = a[5] * scale
  a[6] = a[6] * scale
  a[7] = a[7] * scale
  a[8] = a[8] * scale
  a[9] = a[9] * scale
  return a
end

-- a:get_scale()
function class.get_scale(a)
  return svd3{ a[1], a[2], a[3], a[4], a[5], a[6], a[7], a[8], a[9] }
end

-- a:add(number b, matrix3 c)
-- a:add(matrix3 b, matrix3 c)
-- a:add(number b)
-- a:add(matrix3 b)
function class.add(a, b, c)
  if type(b) == "number" then
    if not c then
      c = a
    end
    a[1] = b + c[1]
    a[2] = b + c[2]
    a[3] = b + c[3]
    a[4] = b + c[4]
    a[5] = b + c[5]
    a[6] = b + c[6]
    a[7] = b + c[7]
    a[8] = b + c[8]
    a[9] = b + c[9]
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
    a[5] = b[5] + c[5]
    a[6] = b[6] + c[6]
    a[7] = b[7] + c[7]
    a[8] = b[8] + c[8]
    a[9] = b[9] + c[9]
    return a
  end
end

-- a:sub(matrix3 b, matrix3 c)
-- a:sub(matrix3 b)
function class.sub(a, b, c)
  if not c then
    c = b
    b = a
  end
  a[1] = b[1] - c[1]
  a[2] = b[2] - c[2]
  a[3] = b[3] - c[3]
  a[4] = b[4] - c[4]
  a[5] = b[5] - c[5]
  a[6] = b[6] - c[6]
  a[7] = b[7] - c[7]
  a[8] = b[8] - c[8]
  a[9] = b[9] - c[9]
  return a
end

-- a:transpose(matrix3 b)
-- a:transpose()
function class.transpose(a, b)
  if b then
    a[2], a[4] = b[4], b[2]
    a[3], a[7] = b[7], b[3]
    a[6], a[8] = b[8], b[6]
    a[1] = b[1]
    a[5] = b[5]
    a[9] = b[9]
    return a
  else
    a[2], a[4] = a[4], a[2]
    a[3], a[7] = a[7], a[3]
    a[6], a[8] = a[8], a[6]
    return a
  end
end

-- a:set(number b, number c, number d, number m21...)
-- a:set(matrix2 b, vector2 c, number d) [EX]
-- a:set(number b, vector2 c) [EX]
-- a:set(vector2 b, number b) [EX]
-- a:set(number b)
-- a:set(vector2 b) [EX]
-- a:set(axis_angle4 b)
-- a:set(quat4 b)
-- a:set(matrix2 b) [EX]
-- a:set(matrix3 b)
-- a:set()
function class.set(a, b, c, d, m21, m22, m23, m31, m32, m33)
  if b then
    if c then
      if d then
        if m21 then
          a[1] = b
          a[2] = c
          a[3] = d
          a[4] = m21
          a[5] = m22
          a[6] = m23
          a[7] = m31
          a[8] = m32
          a[9] = m33
          return a
        else
          a[1] = b[1] * d
          a[2] = b[2] * d
          a[3] = c[1]
          a[4] = b[3] * d
          a[5] = b[4] * d
          a[6] = c[2]
          a[7] = 0
          a[8] = 0
          a[9] = 1
          return a
        end
      else
        if type(b) == "number" then
          a[1] = b
          a[2] = 0
          a[3] = c[1]
          a[4] = 0
          a[5] = b
          a[6] = c[2]
          a[7] = 0
          a[8] = 0
          a[9] = 1
          return a
        else
          a[1] = c
          a[2] = 0
          a[3] = b[1] * c
          a[4] = 0
          a[5] = c
          a[6] = b[2] * c
          a[7] = 0
          a[8] = 0
          a[9] = 1
          return a
        end
      end
    else
      if type(b) == "number" then
        a[1] = b
        a[2] = 0
        a[3] = 0
        a[4] = 0
        a[5] = b
        a[6] = 0
        a[7] = 0
        a[8] = 0
        a[9] = b
        return a
      else
        local n = #b
        if n == 2 then
          a[1] = 1
          a[2] = 0
          a[3] = b[1]
          a[4] = 0
          a[5] = 1
          a[6] = b[2]
          a[7] = 0
          a[8] = 0
          a[9] = 1
          return a
        elseif n == 4 then
          if b.is_axis_angle4 then
            return set_axis_angle4(a, b)
          elseif b.is_quat4 then
            return set_quat4(a, b)
          elseif b.is_matrix2 then
            return set_matrix2(a, b)
          else
            error "bad argument #2 (axis_angle4/quat4/matrix2 expected)"
          end
        else
          a[1] = b[1]
          a[2] = b[2]
          a[3] = b[3]
          a[4] = b[4]
          a[5] = b[5]
          a[6] = b[6]
          a[7] = b[7]
          a[8] = b[8]
          a[9] = b[9]
          return a
        end
      end
    end
  else
    a[1] = 0
    a[2] = 0
    a[3] = 0
    a[4] = 0
    a[5] = 0
    a[6] = 0
    a[7] = 0
    a[8] = 0
    a[9] = 0
    return a
  end
end

-- a:invert(matrix3 b)
-- a:invert()
function class.invert(a, b)
  if not b then
    b = a
  end
  local b11 = b[1]
  local b12 = b[2]
  local b13 = b[3]
  local b21 = b[4]
  local b22 = b[5]
  local b23 = b[6]
  local b31 = b[7]
  local b32 = b[8]
  local b33 = b[9]
  local u = b22 * b33 - b23 * b32
  local v = b23 * b31 - b21 * b33
  local w = b21 * b32 - b22 * b31
  local d = b11 * u + b12 * v + b13 * w
  if d ~= 0 then
    a[1] = u / d
    a[2] = (b13 * b32 - b12 * b33) / d
    a[3] = (b12 * b23 - b13 * b22) / d
    a[4] = v / d
    a[5] = (b11 * b33 - b13 * b31) / d
    a[6] = (b13 * b21 - b11 * b23) / d
    a[7] = w / d
    a[8] = (b12 * b31 - b11 * b32) / d
    a[9] = (b11 * b22 - b12 * b21) / d
    return a
  end
end

-- a:determinant()
function class.determinant(a)
  local a21 = a[4]
  local a22 = a[5]
  local a23 = a[6]
  local a31 = a[7]
  local a32 = a[8]
  local a33 = a[9]
  return a[1] * (a22 * a33 - a32 * a23)
      - a[2] * (a21 * a33 - a31 * a23)
      + a[3] * (a21 * a32 - a31 * a22)
end

-- a:rot_x(number angle)
function class.rot_x(a, angle)
  local c = cos(angle)
  local s = sin(angle)
  a[1] = 1
  a[2] = 0
  a[3] = 0
  a[4] = 0
  a[5] = c
  a[6] = -s
  a[7] = 0
  a[8] = s
  a[9] = c
  return a
end

-- a:rot_y(number angle)
function class.rot_y(a, angle)
  local c = cos(angle)
  local s = sin(angle)
  a[1] = c
  a[2] = 0
  a[3] = s
  a[4] = 0
  a[5] = 1
  a[6] = 0
  a[7] = -s
  a[8] = 0
  a[9] = c
  return a
end

-- a:rot_z(number angle)
function class.rot_z(a, angle)
  local c = cos(angle)
  local s = sin(angle)
  a[1] = c
  a[2] = -s
  a[3] = 0
  a[4] = s
  a[5] = c
  a[6] = 0
  a[7] = 0
  a[8] = 0
  a[9] = 1
  return a
end

-- a:mul_normalize(matrix3 b, matrix3 c)
-- a:mul_normalize(matrix3 b)
function class.mul_normalize(a, b, c)
  return normalize(mul(a, b, c))
end

-- a:mul_transpose_both(matrix3 b, matrix3 c)
function class.mul_transpose_both(a, b, c)
  local b11 = b[1]
  local b12 = b[4]
  local b13 = b[7]
  local b21 = b[2]
  local b22 = b[5]
  local b23 = b[8]
  local b31 = b[3]
  local b32 = b[6]
  local b33 = b[9]

  local c11 = c[1]
  local c12 = c[4]
  local c13 = c[7]
  local c21 = c[2]
  local c22 = c[5]
  local c23 = c[8]
  local c31 = c[3]
  local c32 = c[6]
  local c33 = c[9]

  a[1] = b11 * c11 + b12 * c21 + b13 * c31
  a[2] = b11 * c12 + b12 * c22 + b13 * c32
  a[3] = b11 * c13 + b12 * c23 + b13 * c33
  a[4] = b21 * c11 + b22 * c21 + b23 * c31
  a[5] = b21 * c12 + b22 * c22 + b23 * c32
  a[6] = b21 * c13 + b22 * c23 + b23 * c33
  a[7] = b31 * c11 + b32 * c21 + b33 * c31
  a[8] = b31 * c12 + b32 * c22 + b33 * c32
  a[9] = b31 * c13 + b32 * c23 + b33 * c33
  return a
end

-- a:mul_transpose_left(matrix3 b, matrix3 c)
function class.mul_transpose_left(a, b, c)
  local b11 = b[1]
  local b12 = b[4]
  local b13 = b[7]
  local b21 = b[2]
  local b22 = b[5]
  local b23 = b[8]
  local b31 = b[3]
  local b32 = b[6]
  local b33 = b[9]

  local c11 = c[1]
  local c12 = c[2]
  local c13 = c[3]
  local c21 = c[4]
  local c22 = c[5]
  local c23 = c[6]
  local c31 = c[7]
  local c32 = c[8]
  local c33 = c[9]

  a[1] = b11 * c11 + b12 * c21 + b13 * c31
  a[2] = b11 * c12 + b12 * c22 + b13 * c32
  a[3] = b11 * c13 + b12 * c23 + b13 * c33
  a[4] = b21 * c11 + b22 * c21 + b23 * c31
  a[5] = b21 * c12 + b22 * c22 + b23 * c32
  a[6] = b21 * c13 + b22 * c23 + b23 * c33
  a[7] = b31 * c11 + b32 * c21 + b33 * c31
  a[8] = b31 * c12 + b32 * c22 + b33 * c32
  a[9] = b31 * c13 + b32 * c23 + b33 * c33
  return a
end

-- a:normalize_cp(matrix3 b)
-- a:normalize_cp()
function class.normalize_cp(a, b)
  if not b then
    b = a
  end

  local b11 = b[1]
  local b12 = b[2]
  local b13 = b[3]
  local b21 = b[4]
  local b22 = b[5]
  local b23 = b[6]
  local b31 = b[7]
  local b32 = b[8]
  local b33 = b[9]

  local d = sqrt(b11 * b11 + b21 * b21 + b31 * b31)
  b11 = b11 / d
  b21 = b21 / d
  b31 = b31 / d

  local d = sqrt(b12 * b12 + b22 * b22 + b32 * b32)
  b12 = b12 / d
  b22 = b22 / d
  b32 = b32 / d

  a[1] = b11
  a[2] = b12
  a[3] = b21 * b32 - b22 * b31
  a[4] = b21
  a[5] = b22
  a[6] = b31 * b12 - b32 * b11
  a[7] = b31
  a[8] = b32
  a[9] = b11 * b22 - b12 * b21
  return a
end

-- a:equals(matrix3 b)
function class.equals(a, b)
  return a and b
      and a[1] == b[1] and a[2] == b[2] and a[3] == b[3]
      and a[4] == b[4] and a[5] == b[5] and a[6] == b[6]
      and a[7] == b[7] and a[8] == b[8] and a[9] == b[9]
end

-- a:epsilon_equals(matrix3 b, number epsilon)
function class.epsilon_equals(a, b, epsilon)
  if a and b then
    local m11 = a[1] - b[1]
    local m12 = a[2] - b[2]
    local m13 = a[3] - b[3]
    local m21 = a[4] - b[4]
    local m22 = a[5] - b[5]
    local m23 = a[6] - b[6]
    local m31 = a[7] - b[7]
    local m32 = a[8] - b[8]
    local m33 = a[9] - b[9]

    if m11 < 0 then m11 = -m11 end
    if m12 < 0 then m12 = -m12 end
    if m13 < 0 then m13 = -m13 end
    if m21 < 0 then m21 = -m21 end
    if m22 < 0 then m22 = -m22 end
    if m23 < 0 then m23 = -m23 end
    if m31 < 0 then m31 = -m31 end
    if m32 < 0 then m32 = -m32 end
    if m33 < 0 then m33 = -m33 end

    return m11 <= epsilon and m12 <= epsilon and m13 <= epsilon
        and m21 <= epsilon and m22 <= epsilon and m23 <= epsilon
        and m31 <= epsilon and m32 <= epsilon and m33 <= epsilon
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
  a[5] = 0
  a[6] = 0
  a[7] = 0
  a[8] = 0
  a[9] = 0
  return a
end

-- a:negate(matrix3 b)
-- a:negate()
function class.negate(a, b)
  if not b then
    b = a
  end
  a[1] = -b[1]
  a[2] = -b[2]
  a[3] = -b[3]
  a[4] = -b[4]
  a[5] = -b[5]
  a[6] = -b[6]
  a[7] = -b[7]
  a[8] = -b[8]
  a[9] = -b[9]
  return a
end

-- a:transform(point2 b, point2 c) [EX]
-- a:transform(vector2 b, vector2 c) [EX]
-- a:transform(tuple3 b, tuple3 c)
-- a:transform(point2 b) [EX]
-- a:transform(vector2 b) [EX]
-- a:transform(tuple3 b)
function class.transform(a, b, c)
  if #b == 2 then
    if b.is_point2 then
      return transform_point2(a, b, c)
    elseif b.is_vector2 then
      return transform_vector2(a, b, c)
    else
      error "bad argument #2 (point2 or vector2 expected)"
    end
  else
    if not c then
      c = b
    end
    local x = b[1]
    local y = b[2]
    local z = b[3]
    c[1] = a[1] * x + a[2] * y + a[3] * z
    c[2] = a[4] * x + a[5] * y + a[6] * z
    c[3] = a[7] * x + a[8] * y + a[9] * z
    return c
  end
end

-- a:set_rotation(matrix2 b) [EX]
function class.set_rotation(a, b)
  local sx, sy = svd2{ a[1], a[2], a[4], a[5] }
  a[1] = b[1] * sx
  a[2] = b[2] * sy
  a[4] = b[3] * sx
  a[5] = b[4] * sy
  return a
end

-- a:set_rotation_scale(matrix2 b) [EX]
function class.set_rotation_scale(a, b)
  a[1] = b[1]
  a[2] = b[2]
  a[4] = b[3]
  a[5] = b[4]
  return a
end

-- a:set_translation(vector2 b) [EX]
function class.set_translation(a, b)
  a[3] = b[1]
  a[6] = b[2]
  return a
end

-- a:get(matrix2 b, vector2 c) [EX]
-- a:get(vector2 b) [EX]
-- a:get(matrix2 b) [EX]
function class.get(a, b, c)
  if c then
    local u = { 1, 0, 0, 1 }
    local v = { 1, 0, 0, 1 }
    local s = svd2({ a[1], a[2], a[4], a[5] }, u, v)
    matrix2.mul_transpose_right(b, u, v)
    c[1] = a[3]
    c[2] = a[6]
    return s, b, c
  else
    if #b == 2 then
      b[1] = a[3]
      b[2] = a[6]
      return b
    else
      return matrix2.normalize(matrix2.set(b, a[1], a[2], a[4], a[5]))
    end
  end
end

-- a:get_rotation_scale(matrix2 b) [EX]
function class.get_rotation_scale(a, b)
  b[1] = a[1]
  b[2] = a[2]
  b[3] = a[4]
  b[4] = a[5]
  return b
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
-- class(matrix3 b)
-- class()
return setmetatable(class, {
  __call = function (_, ...)
    return setmetatable(class.set({}, ...), metatable)
  end;
})
