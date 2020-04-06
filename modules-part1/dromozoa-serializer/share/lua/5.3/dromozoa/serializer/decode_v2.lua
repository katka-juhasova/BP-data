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
local tonumber = tonumber

local function decode(source, p, dict, max)
  local op = source:byte(p)
  p = p + 1
  if op == 1 then
    local q = source:find("[\1-\7]", p)
    return q, max, dict[tonumber(source:sub(p, q - 1))]
  elseif op == 2 then
    local q = source:find("[\1-\7]", p)
    return q, max, tonumber(source:sub(p, q - 1))
  elseif op == 3 then
    local q = source:find("[\1-\7]", p)
    return q, max, tonumber(source:sub(p, q - 1)) + 0.0
  elseif op == 4 then
    local q = source:find(":", p, true)
    local size = tonumber(source:sub(p, q - 1))
    p = q + size
    return p + 1, max, source:sub(q + 1, p)
  elseif op == 5 then
    local q = source:find(":", p, true)
    local size = tonumber(source:sub(p, q - 1))
    p = q + size
    local u = source:sub(q + 1, p)
    max = max + 1
    dict[max] = u
    return p + 1, max, u
  elseif op == 6 then
    local q = source:find("[\1-\7]", p)
    local size = tonumber(source:sub(p, q - 1))
    p = q

    local u = {}
    max = max + 1
    dict[max] = u

    for i = 1, size do
      p, max, u[i] = decode(source, p, dict, max)
    end

    local k
    while true do
      p, max, k = decode(source, p, dict, max)
      if k == nil then
        break
      end
      p, max, u[k] = decode(source, p, dict, max)
    end

    return p, max, u
  elseif op == 7 then
    return p, max, nil
  else
    error("unknown op " .. op)
  end
end

return function (source, p)
  local dict = { true, false }
  local _, _, u = decode(source, p, dict, 2)
  return u
end
