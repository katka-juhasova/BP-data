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

local setmetatable = setmetatable

local class = { is_moveto = true }
local metatable = { __index = class }

-- self:set(number a, number b)
-- self:set(tuple2 a)
-- self:set(moveto a)
-- self:set()
function class:set(a, b)
  local p = self[1]
  if a then
    if b then
      p:set(a, b)
      return self
    else
      if #a == 2 then
        p:set(a)
        return self
      else
        p:set(a[1])
        return self
      end
    end
  else
    p:set()
    return self
  end
end

function metatable:__tostring()
  local p = self[1]
  return ("M%.17g,%.17g"):format(p[1], p[2])
end

-- class(number a, number b)
-- class(tuple2 a)
-- class(moveto a)
-- class()
return setmetatable(class, {
  __call = function (_, ...)
    return setmetatable(class.set({ point2() }, ...), metatable)
  end;
})
