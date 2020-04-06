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

local bernstein = require "dromozoa.vecmath.bernstein"

local setmetatable = setmetatable
local type = type

-- a:set_bernstein(bernstein b)
local function set_bernstein(a, b)
  return bernstein.get(b, a)
end

local class = {
  is_polynomial = true;
  set_bernstein = set_bernstein;
}
local metatable = { __index = class }

-- a:set(bernstein b)
-- a:set(polynomial b)
-- a:set()
function class.set(a, b)
  if b then
    if b.is_bernstein then
      return set_bernstein(a, b)
    else
      local n = #b
      for i = 1, n do
        a[i] = b[i]
      end
      for i = n + 1, #a do
        a[i] = nil
      end
      return a
    end
  else
    for i = 1, #a do
      a[i] = nil
    end
    return a
  end
end

-- a:get(bernstein b)
function class.get(a, b)
  return bernstein.set(b, a)
end

-- a:eval(number b)
function class.eval(a, b)
  local n = #a
  local v = a[n]
  for i = n - 1, 1, -1 do
    v = a[i] + b * v
  end
  return v
end

-- a:deriv(polynomial b)
-- a:deriv()
function class.deriv(a, b)
  if b then
    local n = #b
    for i = 1, n - 1 do
      a[i] = b[i + 1] * i
    end
    for i = n, #a do
      a[i] = nil
    end
    return a
  else
    local n = #a
    for i = 1, n - 1 do
      a[i] = a[i + 1] * i
    end
    a[n] = nil
    return a
  end
end

-- a:integ(polynomial b, number c)
-- a:integ(polynomial b)
-- a:integ(number b)
-- a:integ()
function class.integ(a, b, c)
  if b then
    if type(b) == "number" then
      local n = #a
      for i = n, 1, -1 do
        a[i + 1] = a[i] / i
      end
      a[1] = b
      return a
    else
      local n = #b
      for i = n, 1, -1 do
        a[i + 1] = b[i] / i
      end
      a[1] = c or 0
      for i = n + 2, #a do
        a[i] = nil
      end
      return a
    end
  else
    local n = #a
    for i = n, 1, -1 do
      a[i + 1] = a[i] / i
    end
    a[1] = 0
    return a
  end
end

-- a:add(polynomial b, polynomial c)
-- a:add(polynomial b)
function class.add(a, b, c)
  if c then
    local m = #b
    local n = #c
    if m < n then
      for i = 1, m do
        a[i] = b[i] + c[i]
      end
      for i = m + 1, n do
        a[i] = c[i]
      end
      for i = n + 1, #a do
        a[i] = nil
      end
      return a
    else
      for i = 1, n do
        a[i] = b[i] + c[i]
      end
      for i = n + 1, m do
        a[i] = b[i]
      end
      for i = m + 1, #a do
        a[i] = nil
      end
      return a
    end
  else
    local m = #a
    local n = #b
    if m < n then
      for i = 1, m do
        a[i] = a[i] + b[i]
      end
      for i = m + 1, n do
        a[i] = b[i]
      end
      return a
    else
      for i = 1, n do
        a[i] = a[i] + b[i]
      end
      return a
    end
  end
end

-- a:sub(polynomial b, polynomial c)
-- a:sub(polynomial b)
function class.sub(a, b, c)
  if c then
    local m = #b
    local n = #c
    if m < n then
      for i = 1, m do
        a[i] = b[i] - c[i]
      end
      for i = m + 1, n do
        a[i] = -c[i]
      end
      for i = n + 1, #a do
        a[i] = nil
      end
      return a
    else
      for i = 1, n do
        a[i] = b[i] - c[i]
      end
      for i = n + 1, m do
        a[i] = b[i]
      end
      for i = m + 1, #a do
        a[i] = nil
      end
      return a
    end
  else
    local m = #a
    local n = #b
    if m < n then
      for i = 1, m do
        a[i] = a[i] - b[i]
      end
      for i = m + 1, n do
        a[i] = -b[i]
      end
      return a
    else
      for i = 1, n do
        a[i] = a[i] - b[i]
      end
      return a
    end
  end
end

-- a:mul(number b, polynomial c)
-- a:mul(polynomial b, polynomial c)
-- a:mul(number b)
-- a:mul(polynomial b)
function class.mul(a, b, c)
  if type(b) == "number" then
    if c then
      local n = #c
      for i = 1, n do
        a[i] = b * c[i]
      end
      for i = n + 1, #a do
        a[i] = nil
      end
      return a
    else
      for i = 1, #a do
        a[i] = b * a[i]
      end
      return a
    end
  else
    if not c then
      c = b
      b = a
    end
    local m = #b
    local n = #c

    local u = {}
    local v = b[1]
    for j = 1, n do
      u[j] = v * c[j]
    end

    for i = 1, m - 1 do
      local v = b[i + 1]
      for j = 1, n - 1 do
        local k = i + j
        u[k] = u[k] + v * c[j]
      end
      u[i + n] = v * c[n]
    end

    return class.set(a, u)
  end
end

-- class(number b, ...)
-- class(bernstein b)
-- class(polynomial b)
-- class()
return setmetatable(class, {
  __call = function (_, b, ...)
    if b then
      if type(b) == "number" then
        return setmetatable({ b, ... }, metatable)
      else
        return setmetatable(class.set({}, b), metatable)
      end
    else
      return setmetatable({}, metatable)
    end
  end;
})
