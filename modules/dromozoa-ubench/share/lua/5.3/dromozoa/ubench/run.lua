-- Copyright (C) 2015-2018 Tomoyuki Fujimori <moyu@dromozoa.com>
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

local unpack = table.unpack or unpack

local version
if jit then
  version = jit.version
else
  version = _VERSION
end

local function run(n, f, context, ...)
  local timer = unix.timer()
  collectgarbage()
  collectgarbage()
  timer:start()
  for i = 1, n do
    context = f(context, ...)
  end
  timer:stop()
  return timer:elapsed()
end

local function estimate(t, f, context, ...)
  local a = t * 0.99
  local b = t * 1.01
  local n = 1
  while true do
    local elapsed = run(n, f, context, ...)
    if a <= elapsed and elapsed < b then
      return n
    end
    local m = n * t / elapsed
    if m < 1 then
      m = 1
    else
      m = m - m % 1
    end
    if n == m then
      return n
    end
    n = m
  end
end

return function (T, N, benchmarks)
  local results = {}
  for i = 1, #benchmarks do
    local benchmark = benchmarks[i]
    results[i] = {
      version = version;
      name = benchmark[1];
      iteration = estimate(T, unpack(benchmark, 2, benchmark.n));
    }
  end
  local format = "\r[ %" .. #tostring(N) .. "d / " .. N .. " ] " .. version
  for i = 1, N do
    io.stderr:write(format:format(i))
    unix.reserve_stack_pages(8192) -- PTHREAD_STACK_MIN / 2
    for j = 1, #benchmarks do
      local benchmark = benchmarks[j]
      local result = results[j]
      result[i] = run(result.iteration, unpack(benchmark, 2, benchmark.n))
    end
  end
  io.stderr:write "\n"
  return results
end
