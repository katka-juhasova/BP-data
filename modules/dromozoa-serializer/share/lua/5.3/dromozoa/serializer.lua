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

return {
  decode = require "dromozoa.serializer.decode";
  encode = require "dromozoa.serializer.encode";
  encode_v1 = require "dromozoa.serializer.encode_v1";
  encode_v2 = require "dromozoa.serializer.encode_v2";
  equal = require "dromozoa.serializer.equal";
  read = require "dromozoa.serializer.read";
  write = require "dromozoa.serializer.write";
  write_v1 = require "dromozoa.serializer.write_v1";
  write_v2 = require "dromozoa.serializer.write_v2";
}
