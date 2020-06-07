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
local next = next
local pairs = pairs
local rawequal = rawequal
local setmetatable = setmetatable
local type = type
local math_type = math.type

local function equal(a, b, P)
  local t = type(a)
  if t ~= type(b) then
    return false
  elseif t == "nil" or t == "string" or t == "boolean" then
    return a == b
  elseif t == "number" then
    if math_type and math_type(a) ~= math_type(b) then
      return false
    else
      return a == b
    end
  elseif t == "table" then
    if rawequal(a, b) then
      return true
    end

    local p = P[a]
    local q = P[b]
    if p or q then
      return rawequal(p, b) and rawequal(q, a)
    else
      P[a] = b
      P[b] = a
    end

    local m = 0
    for k, u in pairs(a) do
      local t = type(k)
      if t == "number" or t == "string" or t == "boolean" then
        if not equal(u, b[k], P) then
          return false
        end
      elseif t == "table" then
        m = m + 1
      else
        error("table index is " .. t)
      end
    end

    local n = 0
    for k in pairs(b) do
      local t = type(k)
      if t == "number" or t == "string" or t == "boolean" then
        if a[k] == nil then
          return false
        end
      elseif t == "table" then
        n = n + 1
      else
        error("table index is " .. t)
      end
    end

    if m == n then
      if m == 0 then
        return true
      else
        local Q = setmetatable({}, { __index = P })
        local R = {}

        for j, u in pairs(a) do
          if type(j) == "table" then
            local r
            for k, v in pairs(b) do
              if type(k) == "table" and not R[k] then
                if equal(u, v, Q) and equal(j, k, Q) then
                  for l, w in next, Q do
                    P[l] = w
                    Q[l] = nil
                  end
                  r = k
                  break
                else
                  for l in next, Q do
                    Q[l] = nil
                  end
                end
              end
            end
            if r then
              R[r] = true
            else
              return false
            end
          end
        end

        return true
      end
    else
      return false
    end
  else
    error("unsupported type " .. t)
  end
end

return function (a, b)
  return equal(a, b, {})
end
