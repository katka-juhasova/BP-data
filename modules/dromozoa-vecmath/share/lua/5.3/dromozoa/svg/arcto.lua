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

local point2 = require "dromozoa.vecmath.point2"
local point3 = require "dromozoa.vecmath.point3"
local vector2 = require "dromozoa.vecmath.vector2"

local bezier = require "dromozoa.vecmath.bezier"

local setmetatable = setmetatable
local cos = math.cos
local sin = math.sin
local sqrt = math.sqrt

local deg_to_rad = math.pi / 180

local class = { is_arcto = true }
local metatable = { __index = class }

-- self:set(number a, number b, number c, boolean d, boolean e, number f, number g)
-- self:set(tuple2 a, number b, boolean c, boolean d, tuple2 e)
-- self:set(arcto a)
-- self:set()
function class:set(a, b, c, d, e, f, g)
  local r = self[1]
  local p = self[2]
  if a then
    if b then
      if f then
        r:set(a, b)
        p:set(f, g)
        self.angle = c
        self.large_arc = d
        self.sweep = e
        return self
      else
        r:set(a)
        p:set(e)
        self.angle = b
        self.large_arc = c
        self.sweep = d
        return self
      end
    else
      r:set(a[1])
      p:set(a[2])
      self.angle = a.angle
      self.large_arc = a.large_arc
      self.sweep = a.sweep
      return self
    end
  else
    r:set()
    p:set()
    self.angle = 0
    self.large_arc = false
    self.sweep = false
    return self
  end
end

function class:bezier(s, q, result)
  local qx = q[1]
  local qy = q[2]
  local r = self[1]
  local rx = r[1]
  local ry = r[2]
  local p = self[2]
  local px = p[1]
  local py = p[2]
  local angle = self.angle * deg_to_rad
  local sweep = self.sweep
  local large_arc = self.large_arc

  local c = cos(angle)
  local s = sin(angle)
  local m11 = rx * c
  local m12 = -ry * s
  local m21 = rx * s
  local m22 = ry * c
  local n11 = c / rx
  local n12 = s / rx
  local n21 = -s / ry
  local n22 = c / ry

  local x = qx - px
  local y = qy - py
  local X = n11 * x + n12 * y
  local Y = n21 * x + n22 * y
  local Z = X * X + Y * Y

  local sb2 = sqrt(Z)
  local cb2 = sqrt(4 - Z)
  if sweep then
    sb2 = -sb2
  end
  if large_arc then
    cb2 = -cb2
  end
  local sa = -X / sb2
  local ca = Y / sb2

  local x = ca * cb2
  local y = sa * cb2
  local cx = (qx + px - m11 * x - m12 * y) / 2
  local cy = (qy + py - m21 * x - m22 * y) / 2

  local x = qx - cx
  local y = qy - cy
  local c1 = n11 * x + n12 * y
  local s1 = n21 * x + n22 * y

  local x = px - cx
  local y = py - cy
  local c2 = n11 * x + n12 * y
  local s2 = n21 * x + n22 * y

  if large_arc then
    local tx = m11 * ca + m12 * sa + cx
    local ty = m21 * ca + m22 * sa + cy

    local X = c1 - ca
    local Y = s1 - sa
    local Z = X * X + Y * Y
    local sb2 = sqrt(Z)
    local cb2 = sqrt(4 - Z)
    if sweep then
      sb2 = -sb2
    end

    local v = 1 + cb2
    local w = v / 3
    local e = sb2 / v

    local x = e * s1
    local y = -e * c1
    local x1 = m11 * x + m12 * y
    local y1 = m21 * x + m22 * y

    local x = e * sa
    local y = -e * ca
    local x2 = m11 * x + m12 * y
    local y2 = m21 * x + m22 * y

    local x = e * s2
    local y = -e * c2
    local x3 = m11 * x + m12 * y
    local y3 = m21 * x + m22 * y

    local n = #result
    result[n + 1] = bezier(
        point3(qx, qy, 1),
        point3((qx + x1) * w, (qy + y1) * w, w),
        point3((tx - x2) * w, (ty - y2) * w, w),
        point3(tx, ty, 1))
    result[n + 2] = bezier(
        point3(tx, ty, 1),
        point3((tx + x2) * w, (ty + y2) * w, w),
        point3((px - x3) * w, (py - y3) * w, w),
        point3(px, py, 1))
    return p, result
  else
    local v = 1 + cb2
    local w = v / 3
    local e = sb2 / v

    local x = e * s1
    local y = -e * c1
    local x1 = m11 * x + m12 * y
    local y1 = m21 * x + m22 * y

    local x = e * s2
    local y = -e * c2
    local x2 = m11 * x + m12 * y
    local y2 = m21 * x + m22 * y

    result[#result + 1] = bezier(
        point3(qx, qy, 1),
        point3((qx + x1) * w, (qy + y1) * w, w),
        point3((px - x2) * w, (py - y2) * w, w),
        point3(px, py, 1))
    return p, result
  end
end

-- tostring(self)
function metatable:__tostring()
  local r = self[1]
  local p = self[2]
  return ("A%.17g,%.17g %.17g %d,%d %.17g,%.17g"):format(r[1], r[2], self.angle, self.large_arc and 1 or 0, self.sweep and 1 or 0, p[1], p[2])
end

-- class(number a, number b, number c, boolean d, boolean e, number f, number g)
-- class(number a, number b, number c, boolean d, boolean e, tuple2 f)
-- class(tuple2 a, number b, boolean c, boolean d, number e, number f)
-- class(tuple2 a, number b, boolean c, boolean d, tuple2 e)
-- class(arcto a)
-- class()
return setmetatable(class, {
  __call = function (_, ...)
    return setmetatable(class.set({ vector2(), point2() }, ...), metatable)
  end;
})
