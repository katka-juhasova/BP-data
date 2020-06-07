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

local arcto = require "dromozoa.svg.arcto"
local close_path = require "dromozoa.svg.close_path"
local cubic_curveto = require "dromozoa.svg.cubic_curveto"
local lineto = require "dromozoa.svg.lineto"
local moveto = require "dromozoa.svg.moveto"
local quadratic_curveto = require "dromozoa.svg.quadratic_curveto"

local setmetatable = setmetatable
local tostring = tostring
local concat = table.concat

local function rect(self, cx, cy, ux, uy)
  local x1 = cx - ux
  local x2 = cx + ux
  local y1 = cy - uy
  local y2 = cy + uy
  local n = #self
  self[n + 1] = moveto(x1, y1)
  self[n + 2] = lineto(x2, y1)
  self[n + 3] = lineto(x2, y2)
  self[n + 4] = lineto(x1, y2)
  self[n + 5] = lineto(x1, y1)
  self[n + 6] = close_path()
  return self
end

local function ellipse(self, cx, cy, rx, ry)
  local x = cx + rx
  local n = #self
  self[n + 1] = moveto(x, cy)
  self[n + 2] = arcto(rx, ry, 0, false, true, cx, cy + ry)
  self[n + 3] = arcto(rx, ry, 0, false, true, cx - rx, cy)
  self[n + 4] = arcto(rx, ry, 0, false, true, cx, cy - ry)
  self[n + 5] = arcto(rx, ry, 0, false, true, x, cy)
  self[n + 6] = close_path()
  return self
end

local function rounded_rect(self, cx, cy, ux, uy, rx, ry)
  if rx > ux then
    rx = ux
  end
  if ry > uy then
    ry = uy
  end
  if rx == 0 or ry == 0 then
    return rect(self, cx, cy, ux, uy)
  end
  if rx == ux then
    if ry == uy then
      return ellipse(self, cx, cy, rx, ry)
    else
      local x1 = cx - ux
      local x2 = cx + ux
      local y1 = cy - uy
      local y2 = y1 + ry
      local y4 = cy + uy
      local y3 = y4 - ry
      local n = #self
      self[n + 1] = moveto(cx, y1)
      self[n + 2] = arcto(rx, ry, 0, false, true, x2, y2)
      self[n + 3] = lineto(x2, y3)
      self[n + 4] = arcto(rx, ry, 0, false, true, cx, y4)
      self[n + 5] = arcto(rx, ry, 0, false, true, x1, y3)
      self[n + 6] = lineto(x1, y2)
      self[n + 7] = arcto(rx, ry, 0, false, true, cx, y1)
      self[n + 8] = close_path()
      return self
    end
  elseif ry == uy then
    local x1 = cx - ux
    local x2 = x1 + rx
    local x4 = cx + ux
    local x3 = x4 - rx
    local y1 = cy - uy
    local y2 = cy + uy
    local n = #self
    self[n + 1] = moveto(x2, y1)
    self[n + 2] = lineto(x3, y1)
    self[n + 3] = arcto(rx, ry, 0, false, true, x4, cy)
    self[n + 4] = arcto(rx, ry, 0, false, true, x3, y2)
    self[n + 5] = lineto(x2, y2)
    self[n + 6] = arcto(rx, ry, 0, false, true, x1, cy)
    self[n + 7] = arcto(rx, ry, 0, false, true, x2, y1)
    self[n + 8] = close_path()
    return self
  else
    local x1 = cx - ux
    local x2 = x1 + rx
    local x4 = cx + ux
    local x3 = x4 - rx
    local y1 = cy - uy
    local y2 = y1 + ry
    local y4 = cy + uy
    local y3 = y4 - ry
    local n = #self
    self[n + 1] = moveto(x2, y1)
    self[n + 2] = lineto(x3, y1)
    self[n + 3] = arcto(rx, ry, 0, false, true, x4, y2)
    self[n + 4] = lineto(x4, y3)
    self[n + 5] = arcto(rx, ry, 0, false, true, x3, y4)
    self[n + 6] = lineto(x2, y4)
    self[n + 7] = arcto(rx, ry, 0, false, true, x1, y3)
    self[n + 8] = lineto(x1, y2)
    self[n + 9] = arcto(rx, ry, 0, false, true, x2, y1)
    self[n + 10] = close_path()
    return self
  end
end

local class = { is_path_data = true }
local metatable = {
  __index = class;
  ["dromozoa.dom.is_serializable"] = true;
}

function class:M(...)
  self[#self + 1] = moveto(...)
  return self
end

function class:Z()
  self[#self + 1] = close_path()
  return self
end

function class:L(...)
  self[#self + 1] = lineto(...)
  return self
end

function class:C(...)
  self[#self + 1] = cubic_curveto(...)
  return self
end

function class:Q(...)
  self[#self + 1] = quadratic_curveto(...)
  return self
end

function class:A(...)
  self[#self + 1] = arcto(...)
  return self
end

-- self:rect(number a, number b, number c, number d, number e, number f)
-- self:rect(number a, number b, number c, number d)
-- self:rect(tuple2 a, tuple2 b, tuple2 c)
-- self:rect(tuple2 a, tuple2 b)
function class:rect(a, b, c, d, e, f)
  if d then
    if e then
      return rounded_rect(self, a, b, c, d, e, f)
    else
      return rect(self, a, b, c, d)
    end
  else
    if c then
      return rounded_rect(self, a[1], a[2], b[1], b[2], c[1], c[2])
    else
      return rect(self, a[1], a[2], b[1], b[2])
    end
  end
end

-- self:circle(number a, number b, number c)
-- self:circle(tuple2 a, number b)
function class:circle(a, b, c)
  if c then
    return ellipse(self, a, b, c, c)
  else
    return ellipse(self, a[1], a[2], b, b)
  end
end

-- self:ellipse(number a, number b, number c, number d)
-- self:ellipse(tuple2 a, tuple2 b)
function class:ellipse(a, b, c, d)
  if c then
    return ellipse(self, a, b, c, d)
  else
    return ellipse(self, a[1], a[2], b[1], b[2])
  end
end

function class:bezier(result)
  for i = 1, #result do
    result[i] = nil
  end
  local s
  local q
  for i = 1, #self do
    local segment = self[i]
    if segment.is_moveto then
      s = segment[1]
      q = s
    else
      q = segment:bezier(s, q, result)
    end
  end
  return result
end

function metatable:__tostring()
  local buffer = {}
  for i = 1, #self do
    buffer[i] = tostring(self[i])
  end
  return concat(buffer, " ")
end

return setmetatable(class, {
  __call = function ()
    return setmetatable({}, metatable)
  end;
})
