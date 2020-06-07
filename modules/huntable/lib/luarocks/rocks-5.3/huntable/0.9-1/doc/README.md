# huntable
Comparator function for tables with dynamic values

## Installation

1. Install via [LuaRocks](http://luarocks.org):

   `$ luarocks install huntable`

2. [Download](https://github.com/olueiro/huntable/archive/master.zip) and extract inside your project

   `local huntable = require("huntable")`

## Usage

`huntable(source[, condition1[, condition2[, ...]]])`
* `source` Table to lookup;
   - if `source` is nil, function returns false;
* `condition1` ... `conditionN` Table with conditions to check;

## Sample

```lua
-- Consider this table as 'source'
local source = {
  level1_A = {
    level2_A = 1,
    level2_B = "sample",
    level2_B = "1.0",
  },
  level1_B = "sample_B",
  level1_C = {
    level2_A = "sample_C"
    level2_B = {
      level3_A = 10,
      level3_B = nil
    }
  }
}

huntable(source) -- returns true, 'source' is valid
huntable(source, {"level1_A"}) -- returns true, a key named 'level1_A' exists in source
huntable(source, {"level2_A"}) -- returns true, a key named 'level2_A' exists in source
huntable(source, {"level1_Z"}) -- returns false, a key named 'level1_Z' not exists in source
huntable(source, {"level2_A", "level1_B"}) -- returns true, a key named 'level2_A' exists in source AND a key named 'level1_B' exists in source
huntable(source, {level2_A = 1}) -- returns true, a key named 'level2_A' exists in source AND value is integer 1
huntable(source, {level2_A = "sample_C"}) -- returns true, a key named 'level2_A' exists in source AND value is string "sample_C"
huntable(source, {level1_B = "sample_B"}) -- returns true, a key named 'level1_B' exists in source AND value is string "sample_B"
huntable(source, {level2_A = 2}) -- returns false, a key named 'level2_A' exists in source AND value is not integer 2
huntable(source, {level2_A = "sample_Z"}) -- returns false, a key named 'level2_A' exists in source AND value is string "sample_Z"
huntable(source, {level2_A = ">0"}) -- returns true, a key named 'level2_A' exists in source AND value is greater then 0
huntable(source, {level2_B = ">0"}) -- returns true, a key named 'level2_B' exists in source AND value is greater then 0 (1.0)
huntable(source, {level2_A = ">=0"}) -- returns true, a key named 'level2_A' exists in source AND value is greater or equal then 0
huntable(source, {level2_A = "~0"}) -- returns true, a key named 'level2_A' exists in source AND value is non equal to 0
huntable(source, {level2_A = "=0"}) -- returns false, a key named 'level2_A' exists in source AND value is equal to 0
huntable(source, {level1_B = "!Sample_C"}) -- returns true, a key named 'level1_B' exists in source AND value is equal to string "sample_C" (case insensitive comparison)
huntable(source, {level1_B = "~sample_C"}) -- returns false, a key named 'level1_B' exists in source AND value is equal to string "sample_C", cause requires a different value
huntable(source, {level1_B = "~"}) -- returns true, a key named 'level1_B' exists in source AND value is not equal to string ""
huntable(source, {level1_B = "?C"}) -- returns true, a key named 'level1_B' exists in source AND value contains "C" (pattern comparison)
huntable(source, {level1_B = "?^C"}) -- returns false, a key named 'level1_B' exists in source AND value not starts with "C" (pattern comparison)
huntable(source, {level1_B = "?C$"}) -- returns true, a key named 'level1_B' exists in source AND value ends with "C" (pattern comparison)
huntable(source, {level1_B = "=sample_C"}) -- returns true, a key named 'level1_B' exists in source AND value is equal to "sample_C"
huntable(source, {level2_A = {9, 8 , 7, 1}}) -- returns true, a key named 'level2_A' exists in source AND value exists in list (1)
huntable(source, {level2_A = {9, 8 , 7, 6}}) -- returns false, a key named 'level2_A' exists in source AND value not exists in list (1)
huntable(source, {level2_A = 1, level1_B = "sample_B"}) -- returns true, a key named 'level2_A' exists in source AND value is integer 1; a key named 'level1_B' exists in source AND value is string "sample_B"
huntable(source, {level2_A = function(key, value, source) return true end}) -- returns true, a key named 'level2_A' exists in source AND value returns true on function
huntable(source, {level2_A = function(key, value, source) if value == "sample_C" then return true end end}) -- returns true, a key named 'level2_A' exists in source AND value returns true on function, cause exists a key 'level2_A' with value equals to "sample_C"
huntable(source, {{level1_B = "sample_B"}}) -- returns true, a key named 'level1_B' exists in source on root (structured mode - all levels are preserved)
huntable(source, {{level1_A = {}}}) -- returns true, a key named 'level1_A' exists in source  on root (structured mode - all levels are preserved) AND is a table
huntable(source, {{level1_A = {level2_Z = 1}}}) -- returns false, a key named 'level1_A' exists in source on root (structured mode - all levels are preserved) AND is a table AND not contains a key named 'level2_Z'
huntable(source, {"level2_A"}, {"level1_B"}) -- returns true, a key named 'level2_A' exists in source; a key named 'level1_B' exists in source
```

## License

MIT License

Copyright (c) 2016 olueiro

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
