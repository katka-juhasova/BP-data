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

local function read(handle, dict)
  local op, x = handle:read("*n", "*n")
  if op == 1 then
    return dict[x]
  elseif op == 2 then
    return x
  elseif op == 3 then
    return x + 0.0
  elseif op == 4 then
    local _, u = handle:read(1, x)
    return u
  elseif op == 5 then
    local size = handle:read("*n", 1)
    local u = handle:read(size)
    dict[x] = u
    return u
  elseif op == 6 then
    local size = handle:read("*n")
    local u = {}
    dict[x] = u

    for i = 1, size do
      u[i] = read(handle, dict)
    end

    while true do
      local k = read(handle, dict)
      if k == nil then
        break
      end
      u[k] = read(handle, dict)
    end

    return u
  elseif op == 7 then
    return nil
  else
    error("unknown op " .. op)
  end
end

return function (handle)
  local dict = { true, false }
  return (read(handle, dict))
end
