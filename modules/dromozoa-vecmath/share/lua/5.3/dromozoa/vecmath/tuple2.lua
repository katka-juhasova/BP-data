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
  is_tuple2 = true;
  index = {
    1, 2,
    x = 1, y = 2,
  };
}

-- a:set(number b, number y)
-- a:set(tuple2 b)
-- a:set()
function class.set(a, b, y)
  if b then
    if y then
      a[1] = b
      a[2] = y
    else
      a[1] = b[1]
      a[2] = b[2]
    end
    return a
  else
    a[1] = 0
    a[2] = 0
    return a
  end
end

-- a:get(tuple2 b)
function class.get(a, b)
  b[1] = a[1]
  b[2] = a[2]
  return b
end

-- a:add(tuple2 b, tuple2 c)
-- a:add(tuple2 b)
function class.add(a, b, c)
  if not c then
    c = b
    b = a
  end
  a[1] = b[1] + c[1]
  a[2] = b[2] + c[2]
  return a
end

-- a:sub(tuple2 b, tuple2 c)
-- a:sub(tuple2 b)
function class.sub(a, b, c)
  if not c then
    c = b
    b = a
  end
  a[1] = b[1] - c[1]
  a[2] = b[2] - c[2]
  return a
end

-- a:negate(tuple2 b)
-- a:negate()
function class.negate(a, b)
  if not b then
    b = a
  end
  a[1] = -b[1]
  a[2] = -b[2]
  return a
end

-- a:scale(number b, tuple2 c)
-- a:scale(number b)
function class.scale(a, b, c)
  if not c then
    c = a
  end
  a[1] = b * c[1]
  a[2] = b * c[2]
  return a
end

-- a:scale_add(number b, tuple2 c, tuple2 d)
-- a:scale_add(number b, tuple2 c)
function class.scale_add(a, b, c, d)
  if not d then
    d = c
    c = a
  end
  a[1] = b * c[1] + d[1]
  a[2] = b * c[2] + d[2]
  return a
end

-- a:equals(tuple2 b)
function class.equals(a, b)
  return a and b and a[1] == b[1] and a[2] == b[2]
end

-- a:equals(tuple2 b, number epsilon)
function class.epsilon_equals(a, b, epsilon)
  if a and b then
    local x = a[1] - b[1]
    local y = a[2] - b[2]
    if x < 0 then x = -x end
    if y < 0 then y = -y end
    return x <= epsilon and y <= epsilon
  else
    return false
  end
end

-- a:to_string()
function class.to_string(a)
  return format("(%.17g, %.17g)", a[1], a[2])
end

-- a:clamp(number min, number max, tuple2 b)
-- a:clamp(number min, number max)
function class.clamp(a, min, max, b)
  if b then
    local x = b[1]
    local y = b[2]
    if x < min then a[1] = min elseif x > max then a[1] = max else a[1] = x end
    if y < min then a[2] = min elseif y > max then a[2] = max else a[2] = y end
    return a
  else
    local x = a[1]
    local y = a[2]
    if x < min then a[1] = min elseif x > max then a[1] = max end
    if y < min then a[2] = min elseif y > max then a[2] = max end
    return a
  end
end

-- a:clamp_min(number min, tuple2 b)
-- a:clamp_min(number min)
function class.clamp_min(a, min, b)
  if b then
    local x = b[1]
    local y = b[2]
    if x < min then a[1] = min else a[1] = x end
    if y < min then a[2] = min else a[2] = y end
    return a
  else
    if a[1] < min then a[1] = min end
    if a[2] < min then a[2] = min end
    return a
  end
end

-- a:clamp_max(number max, tuple2 b)
-- a:clamp_max(number max)
function class.clamp_max(a, max, b)
  if b then
    local x = b[1]
    local y = b[2]
    if x > max then a[1] = max else a[1] = x end
    if y > max then a[2] = max else a[2] = y end
    return a
  else
    if a[1] > max then a[1] = max end
    if a[2] > max then a[2] = max end
    return a
  end
end

-- a:absolute(tuple2 b)
-- a:absolute()
function class.absolute(a, b)
  if b then
    local x = b[1]
    local y = b[2]
    if x < 0 then a[1] = -x else a[1] = x end
    if y < 0 then a[2] = -y else a[2] = y end
    return a
  else
    local x = a[1]
    local y = a[2]
    if x < 0 then a[1] = -x end
    if y < 0 then a[2] = -y end
    return a
  end
end

-- a:interpolate(tuple2 b, tuple2 c, number d)
-- a:interpolate(tuple2 b, number d)
function class.interpolate(a, b, c, d)
  if not d then
    d = c
    c = b
    b = a
  end
  local beta = 1 - d
  a[1] = beta * b[1] + d * c[1]
  a[2] = beta * b[2] + d * c[2]
  return a
end

return class
