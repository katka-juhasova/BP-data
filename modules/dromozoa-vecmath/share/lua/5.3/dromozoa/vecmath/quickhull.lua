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

local function visit(source, after, p1i, p3i, p2i)
  local i = after[p3i]
  if i == p2i then
    return
  end

  local p1 = source[p1i]
  local p1x = p1[1]
  local p1y = p1[2]
  local p2 = source[p2i]
  local p3 = source[p3i]
  local p3x = p3[1]
  local p3y = p3[2]

  local ux = p3x - p1x
  local uy = p3y - p1y
  local vx = p2[1] - p3x
  local vy = p2[2] - p3y

  local p4i
  local p4d
  local p5d
  local p5i

  local j = p3i
  repeat
    local p = source[i]
    local x = p[1]
    local y = p[2]
    local d = ux * (y - p1y) - uy * (x - p1x)
    if d > 0 then
      if not p4d or p4d < d then
        p4i = i
        p4d = d
        -- i = move_after(after, j, p1i, i)
        local k = after[i]
        after[j] = k
        after[p1i], after[i] = i, after[p1i]
        i = k
      else
        -- i = move_after(after, j, p4i, i)
        local k = after[i]
        after[j] = k
        after[p4i], after[i] = i, after[p4i]
        i = k
      end
    else
      local d = vx * (y - p3y) - vy * (x - p3x)
      if d > 0 then
        if not p5d or p5d < d then
          p5i = i
          p5d = d
          if j == p3i then
            j = i
            i = after[i]
          else
            -- i = move_after(after, j, p3i, i)
            local k = after[i]
            after[j] = k
            after[p3i], after[i] = i, after[p3i]
            i = k
          end
        else
          j = i
          i = after[i]
        end
      else
        -- i = remove_after(after, j, i)
        local k = after[i]
        after[j] = k
        after[i] = nil
        i = k
      end
    end
  until i == p2i

  if p4i then
    visit(source, after, p1i, p4i, p3i)
  end
  if p5i then
    visit(source, after, p3i, p5i, p2i)
  end
end

-- clockwise
return function (source, result)
  if not result then
    result = {}
  end

  local n = #source
  local p1 = source[1]
  local p1i = 1
  local p1x = p1[1]
  local p1y = p1[2]
  local p2i = p1i
  local p2x = p1x
  local p2y = p1y

  for i = 2, n do
    local p = source[i]
    local x = p[1]
    local y = p[2]
    if p1x > x or p1x == x and p1y > y then
      p1i = i
      p1x = x
      p1y = y
    end
    if p2x < x or p2x == x and p2y < y then
      p2i = i
      p2x = x
      p2y = y
    end
  end

  if p1i == p2i then
    result[1] = source[p1i]
    for i = 2, #result do
      result[i] = nil
    end
    return result
  end

  local after = {
    [p1i] = p2i;
    [p2i] = p1i;
  }

  local vx = p2x - p1x
  local vy = p2y - p1y

  local p3i
  local p3d
  local p4i
  local p4d

  for i = 1, n do
    if i ~= p1i and i ~= p2i then
      local p = source[i]
      local d = vx * (p[2] - p1y) - vy * (p[1] - p1x)
      if d > 0 then
        if not p3d or p3d < d then
          p3i = i
          p3d = d
          -- insert_after(after, p1i, i)
          after[p1i], after[i] = i, after[p1i]
        else
          -- insert_after(after, p3i, i)
          after[p3i], after[i] = i, after[p3i]
        end
      elseif d < 0 then
        if not p4d or p4d > d then
          p4i = i
          p4d = d
          -- insert_after(after, p2i, i)
          after[p2i], after[i] = i, after[p2i]
        else
          -- insert_after(after, p4i, i)
          after[p4i], after[i] = i, after[p4i]
        end
      end
    end
  end

  if p3d then
    visit(source, after, p1i, p3i, p2i)
  end
  if p4d then
    visit(source, after, p2i, p4i, p1i)
  end

  local n = 0
  local i = p1i
  repeat
    n = n + 1
    result[n] = source[i]
    i = after[i]
  until i == p1i
  for i = n + 1, #result do
    result[i] = nil
  end
  return result
end
