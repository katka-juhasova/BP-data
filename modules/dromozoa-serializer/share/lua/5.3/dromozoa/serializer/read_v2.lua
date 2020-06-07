-- Copyright (C) 2019 Tomoyuki Fujimori <moyu@dromozoa.com>
--
-- This file is part of dromozoa-serializer.
--
-- dromozoa-serializer is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- dromozoa-serializer is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with dromozoa-serializer.  If not, see <http://www.gnu.org/licenses/>.

local error = error

local function read(handle, dict, max)
  local op, x = handle:read(1, "*n")
  if op == "\1" then
    return max, dict[x]
  elseif op == "\2" then
    return max, x
  elseif op == "\3" then
    return max, x + 0.0
  elseif op == "\4" then
    local _, u = handle:read(1, x)
    return max, u
  elseif op == "\5" then
    local _, u = handle:read(1, x)
    max = max + 1
    dict[max] = u
    return max, u
  elseif op == "\6" then
    local u = {}
    max = max + 1
    dict[max] = u

    for i = 1, x do
      max, u[i] = read(handle, dict, max)
    end

    local k
    while true do
      max, k = read(handle, dict, max)
      if k == nil then
        break
      end
      max, u[k] = read(handle, dict, max)
    end

    return max, u
  elseif op == "\7" then
    return max, nil
  else
    error("unknown op " .. op:byte())
  end
end

return function (handle)
  local dict = { true, false }
  local _, u = read(handle, dict, 2)
  return u
end
