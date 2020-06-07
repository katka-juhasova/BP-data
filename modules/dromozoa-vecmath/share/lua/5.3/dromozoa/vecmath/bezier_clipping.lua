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

local point2 = require "dromozoa.vecmath.point2"
local point3 = require "dromozoa.vecmath.point3"

local bezier = require "dromozoa.vecmath.bezier"
local bezier_focus = require "dromozoa.vecmath.bezier_focus"
local clip_both = require "dromozoa.vecmath.clip_both"
local quickhull = require "dromozoa.vecmath.quickhull"

local sort = table.sort

-- by experimentations
local t_epsilon = 1e-10
local v_epsilon = 1e-12
local d_epsilon = 1e-7

local function fat_line(B1, B2, is_converged)
  local n = B1:size()
  local p = point2()

  B1:get(1, p)
  local px = p[1]
  local py = p[2]

  B1:get(n, p)
  local a = p[2] - py
  local b = px - p[1]
  local c = -(a * px + b * py)

  if is_converged then
    B2:get(1, p)
    local qx = p[1]
    local qy = p[2]
    B2:get(B2:size(), p)
    local ux = p[1] - qx
    local uy = p[2] - qy
    if ux == 0 and uy == 0 then
      a = 0
      b = 0
      c = 0
    else
      ux, uy = -uy, ux
      a = uy
      b = -ux
      c = -uy * px + ux * py
    end
  end

  local d_min = 0
  local d_max = 0
  for i = 2, n - 1 do
    B1:get(i, p)
    local d = a * p[1] + b * p[2] + c
    if d_min > d then
      d_min = d
    end
    if d_max < d then
      d_max = d
    end
  end

  if not B1:is_rational() then
    if n == 3 then
      d_min = d_min / 2
      d_max = d_max / 2
    elseif n == 4 then
      if d_min == 0 then
        d_max = d_max * (3 / 4)
      elseif d_max == 0 then
        d_min = d_min * (3 / 4)
      else
        d_min = d_min * (4 / 9)
        d_max = d_max * (4 / 9)
      end
    end
  end

  return a, b, c, d_min, d_max
end

local function clip_min(H)
  local t1 = 1
  local t2 = 0

  local n = #H
  local p = H[n]
  local pt = p[1]
  local pd = p[2]

  for i = 1, n do
    local q = H[i]
    local qt = q[1]
    local qd = q[2]

    if pd >= 0 then
      if t1 > pt then
        t1 = pt
      end
      if t2 < pt then
        t2 = pt
      end
    end

    local a = pd / (pd - qd)
    if 0 < a and a < 1 then
      local t = pt * (1 - a) + qt * a
      if t1 > t then
        t1 = t
      end
      if t2 < t then
        t2 = t
      end
    end

    pt = qt
    pd = qd
  end

  if t1 <= t2 then
    return t1, t2
  end
end

local function clip_max(H)
  local t1 = 1
  local t2 = 0

  local n = #H
  local p = H[n]
  local pt = p[1]
  local pd = p[2]

  for i = 1, n do
    local q = H[i]
    local qt = q[1]
    local qd = q[2]

    if pd <= 0 then
      if t1 > pt then
        t1 = pt
      end
      if t2 < pt then
        t2 = pt
      end
    end

    local a = pd / (pd - qd)
    if 0 < a and a < 1 then
      local t = pt * (1 - a) + qt * a
      if t1 > t then
        t1 = t
      end
      if t2 < t then
        t2 = t
      end
    end

    pt = qt
    pd = qd
  end

  if t1 <= t2 then
    return t1, t2
  end
end

local function clip(B1, a, b, c, d_min, d_max)
  local n = B1:size()
  local m = n - 1

  if B1:is_rational() then
    local c1 = c - d_min
    local c2 = c - d_max
    local P1 = {}
    local P2 = {}
    local p = point3()
    for i = 1, n do
      B1:get(i, p)
      local t = (i - 1) / m
      local u = a * p[1] + b * p[2]
      local w = p[3]
      P1[i] = point2(t, u + w * c1)
      P2[i] = point2(t, u + w * c2)
    end
    local H = {}
    local t1, t2 = clip_min(quickhull(P1, H))
    if not t1 then
      return
    end
    local t3, t4 = clip_max(quickhull(P2, H))
    if not t3 then
      return
    end
    if t2 - t1 < t4 - t3 then
      return t1, t2
    else
      return t3, t4
    end
  else
    local P = {}
    local p = point2()
    for i = 1, n do
      B1:get(i, p)
      P[i] = point2((i - 1) / m, a * p[1] + b * p[2] + c)
    end
    return clip_both(quickhull(P), d_min, d_max)
  end
end

local function merge(t1, t2, result)
  local U1 = result[1]
  local U2 = result[2]
  local n = #U1
  for i = 1, n do
    local a = U1[i] - t1
    if a < 0 then
      a = -a
    end
    if a <= t_epsilon then
      local b = U2[i] - t2
      if b < 0 then
        b = -b
      end
      if b <= t_epsilon then
        return result
      end
    end
  end
  n = n + 1
  U1[n] = t1
  U2[n] = t2
  return result
end

local function merge_end_points(b1, b2, u1, u2, u3, u4, d, result)
  local p1 = b1:eval(u1, point2())
  local p2 = b1:eval(u2, point2())

  local q = b2:eval(u3, point2())
  if p1:epsilon_equals(q, d) then
    return merge(u1, u3, result)
  end
  if p2:epsilon_equals(q, d) then
    return merge(u2, u3, result)
  end

  b2:eval(u4, q)
  if p1:epsilon_equals(q, d) then
    return merge(u1, u4, result)
  end
  if p2:epsilon_equals(q, d) then
    return merge(u2, u4, result)
  end

  return result
end

local function iterate(b1, b2, u1, u2, u3, u4, m, is_identical, d, result)
  local U1 = result[1]
  local n = #U1
  if n > m then
    return result
  end

  local B1 = bezier(b1):clip(u1, u2)
  local B2 = bezier(b2):clip(u3, u4)

  local a = u2 - u1
  local b = u4 - u3
  local is_converged_a = a <= t_epsilon
  local is_converged_b = b <= t_epsilon

  local t1
  local t2
  if is_converged_a then
    t1 = 0
    t2 = 1
  else
    t1, t2 = clip(B1, fat_line(B2, B1, is_converged_b))
  end
  if not t1 then
    return merge_end_points(b1, b2, u1, u2, u3, u4, d, result)
  end

  local t3
  local t4
  if is_converged_b then
    t3 = 0
    t4 = 1
  else
    t3, t4 = clip(B2, fat_line(B1, B2, is_converged_a))
  end
  if not t3 then
    return merge_end_points(b1, b2, u1, u2, u3, u4, d, result)
  end

  if a * (t2 - t1) <= t_epsilon and b * (t4 - t3) <= t_epsilon then
    return merge(u1 + a * (t1 + t2) / 2, u3 + b * (t3 + t4) / 2, result)
  end

  if t2 - t1 <= 0.8 or t4 - t3 <= 0.8 then
    local v1 = u1 + a * t1
    local v2 = u1 + a * t2
    local v3 = u3 + b * t3
    local v4 = u3 + b * t4
    if t1 > 0 then
      v1 = v1 - v_epsilon
    end
    if t2 < 1 then
      v2 = v2 + v_epsilon
    end
    if t3 > 0 then
      v3 = v3 - v_epsilon
    end
    if t4 < 1 then
      v4 = v4 + v_epsilon
    end
    return iterate(b1, b2, v1, v2, v3, v4, m, is_identical, d, result)
  end

  if not is_identical then
    local F1 = {}
    local F2 = {}
    local F = bezier_focus(b1, b2, u1, u2, u3, u4, { F1, F2 })
    if F.is_identical then
      is_identical = true
    else
      if #F1 > 0 then
        local p = point2()
        local q = point2()
        local F = {}
        for i = 1, #F1 do
          F[i] = { F1[i], F2[i] }
        end
        if a < b then
          sort(F, function (a, b) return a[2] < b[2] end)
          local u5 = u3
          for i = 1, #F do
            local f = F[i]
            local u6 = f[1]
            local u7 = f[2]
            b1:eval(u6, p)
            b2:eval(u7, q)
            if p:epsilon_equals(q, d) then
              merge(u6, u7, result)
              u5 = nil
            else
              if u5 then
                iterate(b1, b2, u1, u2, u5, u7, m, is_identical, d, result)
              end
              u5 = u7
            end
          end
          if u5 then
            iterate(b1, b2, u1, u2, u5, u4, m, is_identical, d, result)
          end
          return result
        else
          sort(F, function (a, b) return a[1] < b[1] end)
          local u5 = u1
          for i = 1, #F do
            local f = F[i]
            local u6 = f[1]
            local u7 = f[2]
            b1:eval(u6, p)
            b2:eval(u7, q)
            if p:epsilon_equals(q, d) then
              merge(u6, u7, result)
              u5 = nil
            else
              if u5 then
                iterate(b1, b2, u5, u6, u3, u4, m, is_identical, d, result)
              end
              u5 = u6
            end
          end
          if u5 then
            iterate(b1, b2, u5, u2, u3, u4, m, is_identical, d, result)
          end
          return result
        end
      end
    end
  end

  if a < b then
    local u5 = (u3 + u4) / 2
    iterate(b1, b2, u1, u2, u3, u5, m, is_identical, d, result)
    return iterate(b1, b2, u1, u2, u5, u4, m, is_identical, d, result)
  else
    local u5 = (u1 + u2) / 2
    iterate(b1, b2, u1, u5, u3, u4, m, is_identical, d, result)
    return iterate(b1, b2, u5, u2, u3, u4, m, is_identical, d, result)
  end
end

return function (b1, b2, t1, t2, t3, t4, result)
  if not t1 then
    t1 = 0
  end
  if not t2 then
    t2 = 1
  end
  if not t3 then
    t3 = 0
  end
  if not t4 then
    t4 = 1
  end
  if not result then
    result = { {}, {} }
  end

  local U1 = result[1]
  local U2 = result[2]
  for i = 1, #U1 do
    U1[i] = nil
    U2[i] = nil
  end

  local m = b1:size()
  local n = b2:size()
  local p = b1:get(1, point2())
  local q = b1:get(m, point2())
  local d1 = p:distance(q)
  b2:get(1, p)
  b2:get(n, p)
  local d2 = p:distance(q)
  local d = d1
  if d < d2 then
    d = d2
  end
  d = d_epsilon * d
  local m = (m - 1) * (n - 1)
  iterate(b1, b2, t1, t2, t3, t4, m, false, d, result)

  local n = #U1
  if n <= m then
    result.is_identical = nil
    return result
  end

  local t_min = U1[1]
  local t_max = t_min
  local u_min = U2[1]
  local u_max = u_min

  U1[1] = nil
  U2[1] = nil

  for i = 2, n do
    local t = U1[i]
    local u = U2[i]

    U1[i] = nil
    U2[i] = nil

    if t_min > t then
      t_min = t
      u_min = u
    end
    if t_max < t then
      t_max = t
      u_max = u
    end
  end

  local b3 = bezier(b1):reverse()
  local b4 = bezier(b2):reverse()
  iterate(b3, b4, 1 - t2, 1 - t1, 1 - t4, 1 - t3, 1, true, d, result)

  for i = 1, #U1 do
    local t = 1 - U1[i]
    local u = 1 - U2[i]

    U1[i] = nil
    U2[i] = nil

    if t_min > t then
      t_min = t
      u_min = u
    end
    if t_max < t then
      t_max = t
      u_max = u
    end
  end

  U1[1] = t_min
  U1[2] = t_max
  U2[1] = u_min
  U2[2] = u_max
  result.is_identical = true
  return result
end
