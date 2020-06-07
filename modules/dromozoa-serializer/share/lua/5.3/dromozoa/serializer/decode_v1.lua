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

local function decode(source, p, dict)
  local op = source:byte(p)
  p = p + 2
  if op == 0x31 then
    local q = source:find("\n", p, true)
    return dict[tonumber(source:sub(p, q))], q + 1
  elseif op == 0x32 then
    local q = source:find("\n", p, true)
    return tonumber(source:sub(p, q)), q + 1
  elseif op == 0x33 then
    local q = source:find("\n", p, true)
    return tonumber(source:sub(p, q)) + 0.0, q + 1
  elseif op == 0x34 then
    local q = source:find(":", p, true)
    local size = tonumber(source:sub(p, q - 1))
    p = q + size
    return source:sub(q + 1, p), p + 2
  elseif op == 0x35 then
    local q = source:find(" ", p, true)
    local ref = tonumber(source:sub(p, q))
    p = q + 1
    local q = source:find(":", p, true)
    local size = tonumber(source:sub(p, q - 1))
    p = q + size
    local u = source:sub(q + 1, p)
    dict[ref] = u
    return u, p + 2
  elseif op == 0x36 then
    local q = source:find(" ", p, true)
    local ref = tonumber(source:sub(p, q))
    p = q + 1
    local q = source:find("\n", p, true)
    local size = tonumber(source:sub(p, q))
    p = q + 1

    local u = {}
    dict[ref] = u

    for i = 1, size do
      u[i], p = decode(source, p, dict)
    end

    local k
    while true do
      k, p = decode(source, p, dict)
      if k == nil then
        break
      end
      u[k], p = decode(source, p, dict)
    end

    return u, p
  elseif op == 0x37 then
    return nil, p + 2
  else
    error("unknown op " .. op)
  end
end

return function (source, p)
  local dict = { true, false }
  return (decode(source, p, dict))
end
