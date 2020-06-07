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

local bezier = require "dromozoa.vecmath.bezier"

local setmetatable = setmetatable

local class = { is_cubic_curveto = true }
local metatable = { __index = class }

-- self:set(number a, number b, number c, number d, number e, number f)
-- self:set(tuple2 a, tuple2 b, tuple2 c)
-- self:set(cubic_curveto a)
-- self:set()
function class:set(a, b, c, d, e, f)
  local p1 = self[1]
  local p2 = self[2]
  local p3 = self[3]
  if a then
    if b then
      if d then
        p1:set(a, b)
        p2:set(c, d)
        p3:set(e, f)
        return self
      else
        p1:set(a)
        p2:set(b)
        p3:set(c)
        return self
      end
    else
      p1:set(b[1])
      p2:set(b[2])
      p3:set(b[3])
      return self
    end
  else
    p1:set()
    p2:set()
    p3:set()
    return self
  end
end

function class:bezier(s, q, result)
  local p1 = self[1]
  local p2 = self[2]
  local p3 = self[3]
  result[#result + 1] = bezier(q, p1, p2, p3)
  return p3, result
end

-- tostring(self)
function metatable:__tostring()
  local p1 = self[1]
  local p2 = self[2]
  local p3 = self[3]
  return ("C%.17g,%.17g %.17g,%.17g %.17g,%.17g"):format(p1[1], p1[2], p2[1], p2[2], p3[1], p3[2])
end

-- class(number a, number b, number c, number d, numer e, number f)
-- class(tuple2 a, tuple2 b, tuple2 c)
-- class(cubic_curveto a)
-- class()
return setmetatable(class, {
  __call = function (_, ...)
    return setmetatable(class.set({ point2(), point2(), point2() }, ...), metatable)
  end;
})
