# lua-benchmark-ips

Lua port of ruby's benchmark-ips

## Usage

```shell
luarocks install benchmark-ips
```

Create a file `example.lua` with:

```lua
local ffi = require 'ffi'
local C = ffi.C

local CLOCK_MONOTONIC_RAW = 4
local function time_ns()
  local ts = ffi.new("struct timespec[1]")
  local ret = C.clock_gettime(CLOCK_MONOTONIC_RAW, ts)

  if ret ~= 0 then
    error("clock_gettime() failed: "..ffi.errno())
  end

  return tonumber(ts[0].tv_sec * 1e9 + ts[0].tv_nsec)
end

local time = os.time

require('benchmark.ips')(function(b)
  b.time = 5
  b.warmup = 2

  b:report('ffi', function() return time_ns() end)
  b:report('syscall', function() return time() end)

  b:compare()
end)
```

And execute the benchmark:

```shell
luajit example.lua
```

To see the output:

```
Warming up --------------------------------------
                 ffi
    754245 i/100ms

             syscall
    362982 i/100ms

Calculating -------------------------------------
 12312309.6 (±1.7%) i/s -   61848090 in   5.024761s
  4613455.0 (±1.2%) i/s -   23230848 in   5.036166s
```
