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
local table_concat = table.concat

local function encode(buffer, n, u, dict, max, string_dictionary, mode)
  if u == nil then
    n = n + 1; buffer[n] = "\0010"
  else
    local t = type(u)
    if t == "boolean" then
      if u then
        n = n + 1; buffer[n] = "\0011"
      else
        n = n + 1; buffer[n] = "\0012"
      end
    elseif t == "number" then
      if math_type and math_type(u) == "integer" then
        n = n + 1; buffer[n] = "\2"
        n = n + 1; buffer[n] = u
      else
        n = n + 1; buffer[n] = ("\3%.17g"):format(u)
      end
    elseif t == "string" then
      if string_dictionary + mode < 2 then
        n = n + 1; buffer[n] = "\4"
        n = n + 1; buffer[n] = #u
        n = n + 1; buffer[n] = ":"
        n = n + 1; buffer[n] = u
      else
        local ref = dict[u]
        if ref then
          n = n + 1; buffer[n] = "\1"
          n = n + 1; buffer[n] = ref
        else
          n = n + 1; buffer[n] = "\5"
          n = n + 1; buffer[n] = #u
          n = n + 1; buffer[n] = ":"
          n = n + 1; buffer[n] = u
          max = max + 1
          dict[u] = max
        end
      end
    elseif t == "table" then
      local ref = dict[u]
      if ref then
        n = n + 1; buffer[n] = "\1"
        n = n + 1; buffer[n] = ref
      else
        local size = #u
        n = n + 1; buffer[n] = "\6"
        n = n + 1; buffer[n] = size
        max = max + 1
        dict[u] = max

        local written = {}
        for i = 1, size do
          n, max = encode(buffer, n, u[i], dict, max, string_dictionary, 0)
          written[i] = true
        end

        for k, v in pairs(u) do
          if not written[k] then
            n, max = encode(buffer, n, k, dict, max, string_dictionary, 1)
            n, max = encode(buffer, n, v, dict, max, string_dictionary, 0)
          end
        end

        n = n + 1; buffer[n] = "\7"
      end
    else
      error("unsupported type " .. t)
    end
  end

  return n, max
end

return function (u, string_dictionary)
  if not string_dictionary then
    string_dictionary = 2
  end
  local buffer = { "2\n" }
  local dict = { [true] = 1, [false] = 2 }
  local n = encode(buffer, 1, u, dict, 2, string_dictionary, 0)
  n = n + 1; buffer[n] = "\7"
  return table_concat(buffer, "", 1, n)
end
