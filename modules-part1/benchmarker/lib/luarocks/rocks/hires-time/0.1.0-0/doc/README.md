lua-hires-time
==

A library to measure the system time with high resolution for lua.

Synopsis
--

```lua
local hires_time = require 'hires_time'

local epoch_micros, err = hires_time.get_epoch_micros()
if err ~= nil then
    -- error handling...
end
```

See also [example](/example/).

Description
--

This package provides a method to measure (and dispense) the system time with high resolution.

Lua runtime's `os.time()` returns the epoch __second__ of the system, however, there is no way to get more high accuracy one. So this library measures and returns the system time as __microseconds__.

The library bridges to `gettimeofday()` function of `sys/time.h`.

Functions
--

### `get_epoch_micros()`

This function measures and returns the system epoch time as __microseconds__.

#### Return value

This method returns the values that accords the following order:

- `epoch_micros` (number or nil): The system epoch time. This variable represents __microseconds__.
- `err` (string or nil): Error response

When `err` is nil, `epoch_micros` has an actual number value. On the other hand, when `err` is not nil, `epoch_micros` is nil.

See also
--

- http://man7.org/linux/man-pages/man2/gettimeofday.2.html

License
--

```
The MIT License (MIT)
Copyright © 2018 moznion, http://moznion.net/ <moznion@gmail.com>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the “Software”), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
```

