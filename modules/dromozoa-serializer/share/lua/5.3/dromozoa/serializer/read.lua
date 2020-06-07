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

local read_v1 = require "dromozoa.serializer.read_v1"
local read_v2 = require "dromozoa.serializer.read_v2"

local error = error

return function (handle)
  local version = handle:read(2)
  if version == "1\n" then
    return read_v1(handle)
  elseif version == "2\n" then
    return read_v2(handle)
  else
    error("unknown version " .. version)
  end
end
