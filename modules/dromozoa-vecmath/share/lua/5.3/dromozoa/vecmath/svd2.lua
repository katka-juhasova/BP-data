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

local sqrt = math.sqrt

return function (m, u, v)
  local m11 = m[1]
  local m12 = m[2]
  local m21 = m[3]
  local m22 = m[4]

  local u11 = 1
  local u12 = 0
  local u21 = 0
  local u22 = 1

  local v11 = 1
  local v12 = 0
  local v21 = 0
  local v22 = 1

  if m21 ~= m12 then
    local x = m21 - m12
    local y = m11 + m22
    local z = sqrt(x * x + y * y)
    local s = x / z
    local c = y / z
    local h = s / (1 + c)

    m11, m12 = m11 - (m12 + m11 * h) * s, m12 + (m11 - m12 * h) * s
    m22 = m22 + (m21 - m22 * h) * s

    if v then
      v11 = c
      v12 = s
      v21 = -s
      v22 = c
    end
  end

  local x = (m22 - m11) * 0.5 / m12
  local t
  if x < 0 then
    t = 1 / (x - sqrt(1 + x * x))
  else
    t = 1 / (x + sqrt(1 + x * x))
  end
  local c = 1 / sqrt(1 + t * t)
  local s = c * t
  local h = s / (1 + c)

  m11, m22 = m11 - m12 * t, m22 + m12 * t

  if u then
    u11 = c
    u12 = s
    u21 = -s
    u22 = c
  end

  if v then
    v11, v12 = v11 - (v12 + v11 * h) * s, v12 + (v11 - v12 * h) * s
    v21, v22 = v21 - (v22 + v21 * h) * s, v22 + (v21 - v22 * h) * s
  end

  if m11 < 0 then
    m11 = -m11
    if v then
      v11 = -v11
      v21 = -v21
    end
  end

  if m22 < 0 then
    m22 = -m22
    if v then
      v12 = -v12
      v22 = -v22
    end
  end

  if m11 > m22 then
    m[1] = m11
    m[2] = 0
    m[3] = 0
    m[4] = m22
    if u then
      u[1] = u11
      u[2] = u12
      u[3] = u21
      u[4] = u22
    end
    if v then
      v[1] = v11
      v[2] = v12
      v[3] = v21
      v[4] = v22
    end
    return m11, m22
  else
    m[1] = m22
    m[2] = 0
    m[3] = 0
    m[4] = m11
    if u then
      u[1] = -u12
      u[2] = u11
      u[3] = -u22
      u[4] = u21
    end
    if v then
      v[1] = -v12
      v[2] = v11
      v[3] = -v22
      v[4] = v21
    end
    return m22, m11
  end
end
