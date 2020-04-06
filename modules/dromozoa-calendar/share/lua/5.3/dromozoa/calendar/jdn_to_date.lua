-- Copyright (C) 2018 Tomoyuki Fujimori <moyu@dromozoa.com>
--
-- This file is part of dromozoa-calendar.
--
-- dromozoa-calendar is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- dromozoa-calendar is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with dromozoa-calendar.  If not, see <http://www.gnu.org/licenses/>.

local floor = math.floor

return function (jdn)
  local A = jdn + 1
  local wday = A % 7
  if A >= 2299162 then
    local a = floor((A - 1867217.25) / 36524.25)
    A = A + 1 + a - floor(a / 4)
  end
  local B = A + 1523
  local C = floor((B - 122.1) / 365.25)
  local D = floor(365.25 * C)
  local E = floor((B - D) / 30.6001)

  local year
  local month
  if E < 14 then
    year = C - 4716
    month = E - 1
  else
    year = C - 4715
    month = E - 13
  end
  local day = B - D - floor(30.6001 * E)
  return year, month, day, wday
end
