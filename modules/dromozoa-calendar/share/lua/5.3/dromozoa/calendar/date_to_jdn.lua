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

return function (year, month, day)
  local y = floor((month - 3) / 12)
  year = year + y
  month = month + 1 - y * 12

  local jdn = floor(365.25 * (year + 4716)) + floor(30.6001 * month) + day - 1524
  if jdn >= 2299161 then
    local A = floor(year / 100)
    jdn = jdn + 2 - A + floor(A / 4)
  end
  return jdn
end
