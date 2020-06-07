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

local decode_v1 = require "dromozoa.serializer.decode_v1"
local decode_v2 = require "dromozoa.serializer.decode_v2"

local error = error

return function (source)
  local version = source:sub(1, 2)
  if version == "1\n" then
    return decode_v1(source, 3)
  elseif version == "2\n" then
    return decode_v2(source, 3)
  else
    error("unknown version " .. version)
  end
end
