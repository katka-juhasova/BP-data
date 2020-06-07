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

local setmetatable = setmetatable

local bezier = require "dromozoa.vecmath.bezier"

local class = { is_close_path = true }
local metatable = { __index = class }

function class:bezier(s, q, result)
  if not q:equals(s) then
    result[#result + 1] = bezier(q, s)
  end
  return s, result
end

-- tostring(self)
function metatable:__tostring()
  return "Z"
end

-- class()
return setmetatable(class, {
  __call = function ()
    return setmetatable({}, metatable)
  end;
})
