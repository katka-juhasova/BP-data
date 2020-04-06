-- Copyright (C) 2017,2018 Tomoyuki Fujimori <moyu@dromozoa.com>
--
-- This file is part of dromozoa-ubench.
--
-- dromozoa-ubench is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- dromozoa-ubench is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with dromozoa-ubench.  If not, see <http://www.gnu.org/licenses/>.

local unix = require "dromozoa.unix"
local max = require "dromozoa.ubench.max"
local min = require "dromozoa.ubench.min"
local stdev = require "dromozoa.ubench.stdev"

local result, png = pcall(require, "dromozoa.png")
if result then
  write_png = function (filename, samples, height)
    local width = #samples

    local rows = {}
    for y = 1, height do
      local row = {}
      for x = 1, width do
        row[x] = "\0"
      end
      rows[y] = row
    end

    local a = min(samples, 1, width)
    local b = max(samples, 1, width) - a
    for x = 1, width do
      local u = (samples[x] - a) * height / b
      u = u - u % 1
      for y = 1, u do
        rows[y][x] = "\255"
      end
    end

    local writer = assert(png.writer())
    local out = assert(io.open(filename, "wb"))
    assert(writer:set_write_fn(function (data)
      out:write(data)
    end))
    assert(writer:set_IHDR {
      width = width;
      height = height;
      bit_depth = 8;
      color_type = png.PNG_COLOR_TYPE_GRAY;
    })
    for y = 1, height do
      local i = height - y + 1
      assert(writer:set_row(i, table.concat(rows[y])))
    end
    assert(writer:write_png())

    out:close()
  end
else
  write_png = function () end
end

return function (results, dir)
  local result, message, code = unix.mkdir(dir)
  if not result then
    if code == unix.EEXIST then
      if unix.band(unix.stat(dir).st_mode, unix.S_IFMT) ~= unix.S_IFDIR then
        error(unix.strerror(unix.ENOTDIR))
      end
    else
      error(message)
    end
  end

  local dataset = {}

  for i = 1, #results do
    local result = results[i]
    local iteration = result.iteration
    local samples1 = {}
    local samples2 = {}
    for j = 1, #result do
      local sample = result[j] * 1000000 / iteration
      samples1[j] = sample
      samples2[j] = sample
    end
    table.sort(samples2)

    write_png(("%s/%04d-01.png"):format(dir, i), samples1, 256)
    write_png(("%s/%04d-02.png"):format(dir, i), samples2, 256)

    local n = #result
    local a = n * 0.25
    a = a - a % 1
    local b = n - a
    a = a + 1

    local data = {
      version = result.version;
      name = result.name;
      min = min(samples2, a, b);
      max = max(samples2, a, b);
    }
    data.sd, data.avg = stdev(samples2, a, b)
    dataset[i] = data
  end

  local out = assert(io.open(("%s/report.txt"):format(dir), "w"))
  out:write "version\tname\tavg\tmin\tmax\tcv\tsd\n"
  for i = 1, #dataset do
    local data = dataset[i]
    out:write(("%s\t%s\t%.17g\t%.17g\t%.17g\t%.17g\t%.17g\n"):format(data.version, data.name, data.avg, data.min, data.max, data.sd / data.avg, data.sd))
  end
  out:close()

  return dataset
end
