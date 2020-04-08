--[[

  Copyright (C) 2017 Masatoshi Teruya

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in
  all copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
  THE SOFTWARE.

  lib/util.lua
  Created by Masatoshi Teruya on 17/08/02.

--]]
--- asign to local
local floor = math.floor;
--- constants
local INFINITE_POS = math.huge;


--- isUnsigned
-- @param n
-- @return ok
local function isUnsigned( n )
    return type( n ) == 'number' and n < INFINITE_POS and n >= 0;
end


--- isUInt
-- @param n
-- @return ok
local function isUInt( n )
    return isUnsigned( n ) and floor( n ) == n;
end


--- isUInt8
-- @param n
-- @return ok
local function isUInt8( n )
    return isUInt( n ) and n < 256;
end


--- isUInt16
-- @param n
-- @return ok
local function isUInt16( n )
    return isUInt( n ) and n < 65536;
end



return {
    isUnsigned = isUnsigned,
    isUInt = isUInt,
    isUInt8 = isUInt8,
    isUInt16 = isUInt16
};
