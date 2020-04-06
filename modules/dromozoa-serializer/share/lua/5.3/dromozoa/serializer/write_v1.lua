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
local pairs = pairs
local type = type
local math_type = math.type

local function write(handle, u, dict, max, string_dictionary)
  if u == nil then
    handle:write "\n1 0"
  else
    local t = type(u)
    if t == "boolean" then
      if u then
        handle:write "\n1 1"
      else
        handle:write "\n1 2"
      end
    elseif t == "number" then
      if math_type and math_type(u) == "integer" then
        handle:write("\n2 ", u)
      else
        handle:write("\n3 ", ("%.17g"):format(u))
      end
    elseif t == "string" then
      if string_dictionary then
        local ref = dict[u]
        if ref then
          handle:write("\n1 ", ref)
        else
          max = max + 1
          handle:write("\n5 ", max, " ", #u, ":", u)
          dict[u] = max
        end
      else
        handle:write("\n4 ", #u, ":", u)
      end
    elseif t == "table" then
      local ref = dict[u]
      if ref then
        handle:write("\n1 ", ref)
      else
        max = max + 1
        local size = #u
        handle:write("\n6 ", max, " ", size)
        dict[u] = max

        local written = {}
        for i = 1, size do
          max = write(handle, u[i], dict, max, string_dictionary)
          written[i] = true
        end
        for k, v in pairs(u) do
          if not written[k] then
            max = write(handle, k, dict, max, string_dictionary)
            max = write(handle, v, dict, max, string_dictionary)
          end
        end

        handle:write "\n7 0"
      end
    else
      error("unsupported type " .. t)
    end
  end

  return max
end

return function (handle, u, string_dictionary)
  local dict = { [true] = 1, [false] = 2 }
  handle:write "1"
  write(handle, u, dict, 2, string_dictionary)
  handle:write "\n"
end
