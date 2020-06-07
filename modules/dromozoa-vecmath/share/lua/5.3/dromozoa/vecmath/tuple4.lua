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

local format = string.format

local class = {
  is_tuple4 = true;
  index = {
    1, 2, 3, 4,
    x = 1, y = 2, z = 3, w = 4,
  };
}

-- a:set(number b, number y, number z, number w)
-- a:set(tuple4 b)
-- a:set()
function class.set(a, b, y, z, w)
  if b then
    if y then
      a[1] = b
      a[2] = y
      a[3] = z
      a[4] = w
      return a
    else
      a[1] = b[1]
      a[2] = b[2]
      a[3] = b[3]
      a[4] = b[4]
      return a
    end
  else
    a[1] = 0
    a[2] = 0
    a[3] = 0
    a[4] = 0
    return a
  end
end

-- a:get(tuple4 b)
function class.get(a, b)
  b[1] = a[1]
  b[2] = a[2]
  b[3] = a[3]
  b[4] = a[4]
  return b
end

-- a:add(tuple4 b, tuple4 c)
-- a:add(tuple4 b)
function class.add(a, b, c)
  if not c then
    c = b
    b = a
  end
  a[1] = b[1] + c[1]
  a[2] = b[2] + c[2]
  a[3] = b[3] + c[3]
  a[4] = b[4] + c[4]
  return a
end

-- a:sub(tuple4 b, tuple4 c)
-- a:sub(tuple4 b)
function class.sub(a, b, c)
  if not c then
    c = b
    b = a
  end
  a[1] = b[1] - c[1]
  a[2] = b[2] - c[2]
  a[3] = b[3] - c[3]
  a[4] = b[4] - c[4]
  return a
end

-- a:negate(tuple4 b)
-- a:negate()
function class.negate(a, b)
  if not b then
    b = a
  end
  a[1] = -b[1]
  a[2] = -b[2]
  a[3] = -b[3]
  a[4] = -b[4]
  return a
end

-- a:scale(number b, tuple4 c)
-- a:scale(number b)
function class.scale(a, b, c)
  if not c then
    c = a
  end
  a[1] = b * c[1]
  a[2] = b * c[2]
  a[3] = b * c[3]
  a[4] = b * c[4]
  return a
end

-- a:scale_add(number b, tuple4 c, tuple4 d)
-- a:scale_add(number b, tuple4 c)
function class.scale_add(a, b, c, d)
  if not d then
    d = c
    c = a
  end
  a[1] = b * c[1] + d[1]
  a[2] = b * c[2] + d[2]
  a[3] = b * c[3] + d[3]
  a[4] = b * c[4] + d[4]
  return a
end

-- a:to_string()
function class.to_string(a)
  return format("(%.17g, %.17g, %.17g, %.17g)", a[1], a[2], a[3], a[4])
end

-- a:equals(tuple4 b)
function class.equals(a, b)
  return a and b and a[1] == b[1] and a[2] == b[2] and a[3] == b[3] and a[4] == b[4]
end

-- a:epsilon_equals(tuple4 b, number epsilon)
function class.epsilon_equals(a, b, epsilon)
  if a and b then
    local x = a[1] - b[1]
    local y = a[2] - b[2]
    local z = a[3] - b[3]
    local w = a[4] - b[4]
    if x < 0 then x = -x end
    if y < 0 then y = -y end
    if z < 0 then z = -z end
    if w < 0 then w = -w end
    return x <= epsilon and y <= epsilon and z <= epsilon and w <= epsilon
  else
    return false
  end
end

-- a:clamp(number min, number max, tuple4 b)
-- a:clamp(number min, number max)
function class.clamp(a, min, max, b)
  if b then
    local x = b[1]
    local y = b[2]
    local z = b[3]
    local w = b[4]
    if x < min then a[1] = min elseif x > max then a[1] = max else a[1] = x end
    if y < min then a[2] = min elseif y > max then a[2] = max else a[2] = y end
    if z < min then a[3] = min elseif z > max then a[3] = max else a[3] = z end
    if w < min then a[4] = min elseif w > max then a[4] = max else a[4] = w end
    return a
  else
    local x = a[1]
    local y = a[2]
    local z = a[3]
    local w = a[4]
    if x < min then a[1] = min elseif x > max then a[1] = max end
    if y < min then a[2] = min elseif y > max then a[2] = max end
    if z < min then a[3] = min elseif z > max then a[3] = max end
    if w < min then a[4] = min elseif w > max then a[4] = max end
    return a
  end
end

-- a:clamp_min(number min, tuple4 b)
-- a:clamp_min(number min)
function class.clamp_min(a, min, b)
  if b then
    local x = b[1]
    local y = b[2]
    local z = b[3]
    local w = b[4]
    if x < min then a[1] = min else a[1] = x end
    if y < min then a[2] = min else a[2] = y end
    if z < min then a[3] = min else a[3] = z end
    if w < min then a[4] = min else a[4] = w end
    return a
  else
    if a[1] < min then a[1] = min end
    if a[2] < min then a[2] = min end
    if a[3] < min then a[3] = min end
    if a[4] < min then a[4] = min end
    return a
  end
end

-- a:clamp_max(number max, tuple4 b)
-- a:clamp_max(number max)
function class.clamp_max(a, max, b)
  if b then
    local x = b[1]
    local y = b[2]
    local z = b[3]
    local w = b[4]
    if x > max then a[1] = max else a[1] = x end
    if y > max then a[2] = max else a[2] = y end
    if z > max then a[3] = max else a[3] = z end
    if w > max then a[4] = max else a[4] = w end
    return a
  else
    if a[1] > max then a[1] = max end
    if a[2] > max then a[2] = max end
    if a[3] > max then a[3] = max end
    if a[4] > max then a[4] = max end
    return a
  end
end

-- a:absolute(tuple4 b)
-- a:absolute()
function class.absolute(a, b)
  if b then
    local x = b[1]
    local y = b[2]
    local z = b[3]
    local w = b[4]
    if x < 0 then a[1] = -x else a[1] = x end
    if y < 0 then a[2] = -y else a[2] = y end
    if z < 0 then a[3] = -z else a[3] = z end
    if w < 0 then a[4] = -w else a[4] = w end
    return a
  else
    local x = a[1]
    local y = a[2]
    local z = a[3]
    local w = a[4]
    if x < 0 then a[1] = -x end
    if y < 0 then a[2] = -y end
    if z < 0 then a[3] = -z end
    if w < 0 then a[4] = -w end
    return a
  end
end

-- a:interpolate(tuple4 b, tuple4 c, number d)
-- a:interpolate(tuple4 b, number c)
function class.interpolate(a, b, c, d)
  if not d then
    d = c
    c = b
    b = a
  end
  local beta = 1 - d
  a[1] = beta * b[1] + d * c[1]
  a[2] = beta * b[2] + d * c[2]
  a[3] = beta * b[3] + d * c[3]
  a[4] = beta * b[4] + d * c[4]
  return a
end

return class
