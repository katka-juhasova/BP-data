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

local tuple4 = require "dromozoa.vecmath.tuple4"

local rawget = rawget
local rawset = rawset
local setmetatable = setmetatable
local acos = math.acos
local cos = math.cos
local sin = math.sin
local sqrt = math.sqrt

local function set_axis_angle4(a, b)
  local x = b[1]
  local y = b[2]
  local z = b[3]
  local u = b[4] * 0.5
  local v = sin(u) / sqrt(x * x + y * y + z * z)
  a[1] = x * v
  a[2] = y * v
  a[3] = z * v
  a[4] = cos(u)
  return a
end

local function set_matrix3(a, b11, b12, b13, b21, b22, b23, b31, b32, b33)
  local v = b11 + b22 + b33
  if v >= 0 then
    local w = sqrt(v + 1) * 0.5
    local d = w * 4
    a[1] = (b32 - b23) / d
    a[2] = (b13 - b31) / d
    a[3] = (b21 - b12) / d
    a[4] = w
    return a
  else
    if b11 > b22 then
      if b11 > b33 then
        local x = sqrt(b11 - b22 - b33 + 1) * 0.5
        local d = x * 4
        a[1] = x
        a[2] = (b21 + b12) / d
        a[3] = (b13 + b31) / d
        a[4] = (b32 - b23) / d
        return a
      end
    else
      if b22 > b33 then
        local y = sqrt(b22 - b33 - b11 + 1) * 0.5
        local d = y * 4
        a[1] = (b21 + b12) / d
        a[2] = y
        a[3] = (b32 + b23) / d
        a[4] = (b13 - b31) / d
        return a
      end
    end
    local z = sqrt(b33 - b11 - b22 + 1) * 0.5
    local d = z * 4
    a[1] = (b13 + b31) / d
    a[2] = (b32 + b23) / d
    a[3] = z
    a[4] = (b21 - b12) / d
    return a
  end
end

local super = tuple4
local class = {
  is_quat4 = true;
  set_axis_angle4 = set_axis_angle4;
}
local metatable = { __tostring = super.to_string }

-- a:set(number b, number y, number z, number w)
-- a:set(axis_angle4 b)
-- a:set(tuple4 b)
-- a:set(matrix3 b)
-- a:set(matrix4 b)
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
      local n = #b
      if n == 4 then
        if b.is_axis_angle4 then
          return set_axis_angle4(a, b)
        else
          a[1] = b[1]
          a[2] = b[2]
          a[3] = b[3]
          a[4] = b[4]
          return a
        end
      elseif n == 9 then
        return set_matrix3(a, b[1], b[2], b[3], b[4], b[5], b[6], b[7], b[8], b[9])
      else
        return set_matrix3(a, b[1], b[2], b[3], b[5], b[6], b[7], b[9], b[10], b[11])
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

-- a:conjugate(quat4 b)
-- a:conjugate()
function class.conjugate(a, b)
  if b then
    a[1] = -b[1]
    a[2] = -b[2]
    a[3] = -b[3]
    a[4] = b[4]
    return a
  else
    a[1] = -a[1]
    a[2] = -a[2]
    a[3] = -a[3]
    return a
  end
end

-- a:mul(quat4 b, quat4 c)
-- a:mul(quat4 b)
function class.mul(a, b, c)
  if not c then
    c = b
    b = a
  end
  local bx = b[1]
  local by = b[2]
  local bz = b[3]
  local bw = b[4]
  local cx = c[1]
  local cy = c[2]
  local cz = c[3]
  local cw = c[4]
  a[1] = bx * cw + bw * cx - bz * cy + by * cz
  a[2] = by * cw + bz * cx + bw * cy - bx * cz
  a[3] = bz * cw - by * cx + bx * cy + bw * cz
  a[4] = bw * cw - bx * cx - by * cy - bz * cz
  return a
end

-- a:mul_inverse(quat4 b, quat4 c)
-- a:mul_inverse(quat4 b)
function class.mul_inverse(a, b, c)
  if not c then
    c = b
    b = a
  end
  local bx = b[1]
  local by = b[2]
  local bz = b[3]
  local bw = b[4]
  local cx = c[1]
  local cy = c[2]
  local cz = c[3]
  local cw = c[4]
  local d = cx * cx + cy * cy + cz * cz + cw * cw
  a[1] = (bx * cw - bw * cx + bz * cy - by * cz) / d
  a[2] = (by * cw - bz * cx - bw * cy + bx * cz) / d
  a[3] = (bz * cw + by * cx - bx * cy - bw * cz) / d
  a[4] = (bw * cw + bx * cx + by * cy + bz * cz) / d
  return a
end

-- a:inverse(quat4 b)
-- a:inverse()
function class.inverse(a, b)
  if not b then
    b = a
  end
  local x = b[1]
  local y = b[2]
  local z = b[3]
  local w = b[4]
  local d = x * x + y * y + z * z + w * w
  a[1] = -x / d
  a[2] = -y / d
  a[3] = -z / d
  a[4] = w / d
  return a
end

-- a:normalize(quat4 b)
-- a:normalize()
function class.normalize(a, b)
  if not b then
    b = a
  end
  local x = b[1]
  local y = b[2]
  local z = b[3]
  local w = b[4]
  local d = sqrt(x * x + y * y + z * z + w * w)
  a[1] = x / d
  a[2] = y / d
  a[3] = z / d
  a[4] = w / d
  return a
end

-- a:interpolate(quat4 b, quat4 c, number d)
-- a:interpolate(quat4 b, number c)
function class.interpolate(a, b, c, d)
  if not d then
    d = c
    c = b
    b = a
  end

  local bx = b[1]
  local by = b[2]
  local bz = b[3]
  local bw = b[4]
  local bd = sqrt(bx * bx + by * by + bz * bz + bw * bw)
  bx = bx / bd
  by = by / bd
  bz = bz / bd
  bw = bw / bd

  local cx = c[1]
  local cy = c[2]
  local cz = c[3]
  local cw = c[4]
  local cd = sqrt(cx * cx + cy * cy + cz * cz + cw * cw)
  cx = cx / cd
  cy = cy / cd
  cz = cz / cd
  cw = cw / cd

  local dot = bx * cx + by * cy + bz * cz + bw * cw
  if dot < 0 then
    local omega = acos(-dot)
    local s = sin(omega)
    local beta = -sin((1 - d) * omega) / s
    local alpha = sin(d * omega) / s
    a[1] = beta * bx + alpha * cx
    a[2] = beta * by + alpha * cy
    a[3] = beta * bz + alpha * cz
    a[4] = beta * bw + alpha * cw
  else
    local omega = acos(dot)
    local s = sin(omega)
    local beta = sin((1 - d) * omega) / s
    local alpha = sin(d * omega) / s
    a[1] = beta * bx + alpha * cx
    a[2] = beta * by + alpha * cy
    a[3] = beta * bz + alpha * cz
    a[4] = beta * bw + alpha * cw
  end
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

-- class(number b, number y, number z, number e)
-- class(tuple4 b)
-- class()
return setmetatable(class, {
  __index = super;
  __call = function (_, ...)
    return setmetatable(class.set({}, ...), metatable)
  end;
})
