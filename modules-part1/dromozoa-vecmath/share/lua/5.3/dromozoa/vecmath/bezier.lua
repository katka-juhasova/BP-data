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
local vector2 = require "dromozoa.vecmath.vector2"

local bernstein = require "dromozoa.vecmath.bernstein"
local polynomial = require "dromozoa.vecmath.polynomial"

local setmetatable = setmetatable
local type = type
local concat = table.concat

-- a:to_string()
local function to_string(a)
  local buffer = {}
  local X = a[1]
  local Y = a[2]
  local Z = a[3]
  if Z[1] then
    for i = 1, #X do
      buffer[i] = ("(%.17g, %.17g, %.17g)\n"):format(X[i], Y[i], Z[i])
    end
    return concat(buffer)
  else
    for i = 1, #X do
      buffer[i] = ("(%.17g, %.17g)\n"):format(X[i], Y[i])
    end
    return concat(buffer)
  end
end

-- a:get_tuple2(number b, point2 c)
local function get_tuple2(a, b, c)
  local z = a[3][b]
  if z then
    c[1] = a[1][b] / z
    c[2] = a[2][b] / z
    return c
  else
    c[1] = a[1][b]
    c[2] = a[2][b]
    return c
  end
end

-- a:get_tuple3(number b, point3 c)
local function get_tuple3(a, b, c)
  c[1] = a[1][b]
  c[2] = a[2][b]
  c[3] = a[3][b] or 1
  return c
end

-- a:eval_tuple2(number b, point2 c)
local function eval_tuple2(a, b, c)
  local Z = a[3]
  local t = {}
  if Z[1] then
    local z = bernstein.eval(Z, b, t)
    c[1] = bernstein.eval(a[1], b, t) / z
    c[2] = bernstein.eval(a[2], b, t) / z
    return c
  else
    c[1] = bernstein.eval(a[1], b, t)
    c[2] = bernstein.eval(a[2], b, t)
    return c
  end
end

-- a:eval_tuple3(number b, point3 c)
local function eval_tuple3(a, b, c)
  local Z = a[3]
  local t = {}
  if Z[1] then
    c[1] = bernstein.eval(a[1], b, t)
    c[2] = bernstein.eval(a[2], b, t)
    c[3] = bernstein.eval(a[3], b, t)
    return c
  else
    c[1] = bernstein.eval(a[1], b, t)
    c[2] = bernstein.eval(a[2], b, t)
    c[3] = 1
    return c
  end
end

local class = {
  is_bezier = true;
  to_string = to_string;
  get_tuple2 = get_tuple2;
  get_tuple3 = get_tuple3;
  eval_tuple2 = eval_tuple2;
  eval_tuple3 = eval_tuple3;
}
local metatable = {
  __index = class;
  __tostring = to_string;
}

-- a:set(point2 b, point2 c, ...)
-- a:set(point3 b, point3 c, ...)
-- a:set(bezier b)
-- a:set()
function class.set(a, b, c, ...)
  local X = a[1]
  local Y = a[2]
  local Z = a[3]
  if b then
    if c then
      if #b == 2 then
        local points = { b, c, ... }
        local n = #points
        for i = 1, n do
          local p = points[i]
          X[i] = p[1]
          Y[i] = p[2]
        end
        for i = n + 1, #X do
          X[i] = nil
          Y[i] = nil
        end
        bernstein.set(Z)
        return a
      else
        local points = { b, c, ... }
        local n = #points
        for i = 1, n do
          local p = points[i]
          X[i] = p[1]
          Y[i] = p[2]
          Z[i] = p[3]
        end
        for i = n + 1, #X do
          X[i] = nil
          Y[i] = nil
          Z[i] = nil
        end
        return a
      end
    else
      bernstein.set(X, b[1])
      bernstein.set(Y, b[2])
      bernstein.set(Z, b[3])
      return a
    end
  else
    bernstein.set(X)
    bernstein.set(Y)
    bernstein.set(Z)
    return a
  end
end

-- a:set_catmull_rom(point2 p1, point2 p2, point2 p3, point2 p4)
function class.set_catmull_rom(a, p1, p2, p3, p4)
  local X = a[1]
  local Y = a[2]

  local p2x = p2[1]
  local p3x = p3[1]
  local p2y = p2[2]
  local p3y = p3[2]

  X[1] = p2x
  X[2] = p2x + (p3x - p1[1]) / 6
  X[3] = p3x + (p2x - p4[1]) / 6
  X[4] = p3x

  Y[1] = p2y
  Y[2] = p2y + (p3y - p1[2]) / 6
  Y[3] = p3y + (p2y - p4[2]) / 6
  Y[4] = p3y

  for i = 5, #X do
    X[i] = nil
    Y[i] = nil
  end
  bernstein.set(a[3])

  return a
end

-- a:get(number b, point2 c)
-- a:get(number b, point3 c)
function class.get(a, b, c)
  if #c == 2 then
    return get_tuple2(a, b, c)
  else
    return get_tuple3(a, b, c)
  end
end

-- a:eval(number b, point2 c)
-- a:eval(number b, point3 c)
function class.eval(a, b, c)
  if #c == 2 then
    return eval_tuple2(a, b, c)
  else
    return eval_tuple3(a, b, c)
  end
end

-- a:clip(number min, number max, bezier b)
-- a:clip(number min, number max)
function class.clip(a, min, max, b)
  local t = 0
  if min < 1 then
    t = (max - min) / (1 - min)
  end

  if b then
    local AX = a[1]
    local AY = a[2]
    local AZ = a[3]
    local BX = b[1]
    local BY = b[2]
    local BZ = b[3]

    bernstein.eval(BX, min, nil, AX)
    bernstein.eval(AX, t, AX)
    bernstein.eval(BY, min, nil, AY)
    bernstein.eval(AY, t, AY)
    if BZ[1] then
      bernstein.eval(BZ, min, nil, AZ)
      bernstein.eval(AZ, t, AZ)
    else
      bernstein.set(AZ)
    end

    return a
  else
    local X = a[1]
    local Y = a[2]
    local Z = a[3]

    bernstein.eval(X, min, nil, X)
    bernstein.eval(X, t, X)
    bernstein.eval(Y, min, nil, Y)
    bernstein.eval(Y, t, Y)
    if Z[1] then
      bernstein.eval(Z, min, nil, Z)
      bernstein.eval(Z, t, Z)
    end

    return a
  end
end

-- a:reverse(bezier b)
-- a:reverse()
function class.reverse(a, b)
  if b then
    bernstein.reverse(a[1], b[1])
    bernstein.reverse(a[2], b[2])
    bernstein.reverse(a[3], b[3])
    return a
  else
    bernstein.reverse(a[1])
    bernstein.reverse(a[2])
    bernstein.reverse(a[3])
    return a
  end
end

-- a:deriv(bezier b)
-- a:deriv()
function class.deriv(a, b)
  if b then
    local AX = a[1]
    local AY = a[2]
    local AZ = a[3]
    local BX = b[1]
    local BY = b[2]
    local BZ = b[3]

    if BZ[1] then
      local PX = bernstein.get(BX, polynomial())
      local PY = bernstein.get(BY, polynomial())
      local PZ = bernstein.get(BZ, polynomial())
      local QX = polynomial():deriv(PX)
      local QY = polynomial():deriv(PY)
      local QZ = polynomial():deriv(PZ)
      QX:mul(PZ)
      PX:mul(QZ)
      QY:mul(PZ)
      PY:mul(QZ)
      QX:sub(PX)
      QY:sub(PY)
      PZ:mul(PZ)
      bernstein.set(AX, QX)
      bernstein.elevate(AX)
      bernstein.set(AY, QY)
      bernstein.elevate(AY)
      bernstein.set(AZ, PZ)
      return a
    else
      bernstein.deriv(AX, BX)
      bernstein.deriv(AY, BY)
      bernstein.set(AZ)
      return a
    end
  else
    local X = a[1]
    local Y = a[2]
    local Z = a[3]

    if Z[1] then
      local PX = bernstein.get(X, polynomial())
      local PY = bernstein.get(Y, polynomial())
      local PZ = bernstein.get(Z, polynomial())
      local QX = polynomial():deriv(PX)
      local QY = polynomial():deriv(PY)
      local QZ = polynomial():deriv(PZ)
      QX:mul(PZ)
      PX:mul(QZ)
      QY:mul(PZ)
      PY:mul(QZ)
      QX:sub(PX)
      QY:sub(PY)
      PZ:mul(PZ)
      bernstein.set(X, QX)
      bernstein.elevate(X)
      bernstein.set(Y, QY)
      bernstein.elevate(Y)
      bernstein.set(Z, PZ)
      return a
    else
      bernstein.deriv(X)
      bernstein.deriv(Y)
      return a
    end
  end
end

-- a:focus(bezier b)
-- a:focus()
function class.focus(a, b)
  if b then
    local AX = a[1]
    local AY = a[2]
    local AZ = a[3]
    local BX = b[1]
    local BY = b[2]
    local BZ = b[3]

    if BZ[1] then
      local PX = bernstein.get(BX, polynomial())
      local PY = bernstein.get(BY, polynomial())
      local PZ = bernstein.get(BZ, polynomial())
      local QX = polynomial():deriv(PX)
      local QY = polynomial():deriv(PY)
      local QZ = polynomial():deriv(PZ)
      local R = polynomial()
      QX:mul(PZ):sub(R:mul(PX, QZ))
      QY:mul(PZ):sub(R:mul(PY, QZ))
      QZ:mul(PZ, PZ)
      local z0 = QZ:eval(0)
      local z1 = QZ:eval(1)
      local M = matrix2(-QY:eval(0) / z0, QY:eval(1) / z1, QX:eval(0) / z0, -QX:eval(1) / z1)
      if M:invert() then
        local u = M:transform { PX:eval(1) - PX:eval(0), PY:eval(1) - PY:eval(0) }
        local v = u[1]
        local C = polynomial(v, u[2] - v)
        PX:mul(PZ):sub(QY:mul(C))
        PY:mul(PZ):add(QX:mul(C))
        bernstein.set(AX, PX)
        bernstein.set(AY, PY)
        bernstein.set(AZ, QZ)
        return a
      end
    else
      local PX = bernstein.get(BX, polynomial())
      local PY = bernstein.get(BY, polynomial())
      local QX = polynomial():deriv(PX)
      local QY = polynomial():deriv(PY)
      local M = matrix2(-QY:eval(0), QY:eval(1), QX:eval(0), -QX:eval(1))
      if M:invert() then
        local u = M:transform { PX:eval(1) - PX:eval(0), PY:eval(1) - PY:eval(0) }
        local v = u[1]
        local C = polynomial(v, u[2] - v)
        bernstein.set(AX, PX:sub(QY:mul(C)))
        bernstein.set(AY, PY:add(QX:mul(C)))
        bernstein.set(AZ)
        return a
      end
    end
  else
    local X = a[1]
    local Y = a[2]
    local Z = a[3]

    if Z[1] then
      local PX = bernstein.get(X, polynomial())
      local PY = bernstein.get(Y, polynomial())
      local PZ = bernstein.get(Z, polynomial())
      local QX = polynomial():deriv(PX)
      local QY = polynomial():deriv(PY)
      local QZ = polynomial():deriv(PZ)
      local R = polynomial()
      QX:mul(PZ):sub(R:mul(PX, QZ))
      QY:mul(PZ):sub(R:mul(PY, QZ))
      QZ:mul(PZ, PZ)
      local z0 = QZ:eval(0)
      local z1 = QZ:eval(1)
      local M = matrix2(-QY:eval(0) / z0, QY:eval(1) / z1, QX:eval(0) / z0, -QX:eval(1) / z1)
      if M:invert() then
        local u = M:transform { PX:eval(1) - PX:eval(0), PY:eval(1) - PY:eval(0) }
        local v = u[1]
        local C = polynomial(v, u[2] - v)
        PX:mul(PZ):sub(QY:mul(C))
        PY:mul(PZ):add(QX:mul(C))
        bernstein.set(X, PX)
        bernstein.set(Y, PY)
        bernstein.set(Z, QZ)
        return a
      end
    else
      local PX = bernstein.get(X, polynomial())
      local PY = bernstein.get(Y, polynomial())
      local QX = polynomial():deriv(PX)
      local QY = polynomial():deriv(PY)
      local M = matrix2(-QY:eval(0), QY:eval(1), QX:eval(0), -QX:eval(1))
      if M:invert() then
        local u = M:transform { PX:eval(1) - PX:eval(0), PY:eval(1) - PY:eval(0) }
        local v = u[1]
        local C = polynomial(v, u[2] - v)
        bernstein.set(X, PX:sub(QY:mul(C)))
        bernstein.set(Y, PY:add(QX:mul(C)))
        return a
      end
    end
  end
end

-- a:size()
function class.size(a)
  return #a[1]
end

-- a:is_rational()
function class.is_rational(a)
  return a[3][1]
end

-- class(point2 b, point2 c, ...)
-- class(point3 b, point3 c, ...)
-- class(bezier b)
-- class()
return setmetatable(class, {
  __call = function (_, ...)
    return setmetatable(class.set({ bernstein(), bernstein(), bernstein() }, ...), metatable)
  end;
})
