--[[

  Copyright (C) 2018 Masatoshi Teruya

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

  trim.lua
  lua-string-trim
  Created by Masatoshi Teruya on 18/04/26.

--]]
--- file-scope variables
local type = type;
local error = error;
local strsub = string.sub;
local strfind = string.find;

--- trim
-- @param str
-- @return str
local function trim( str )
    if type( str ) ~= 'string' then
        error( 'str must be string', 2 );
    elseif str == '' then
        return '';
    else
        local _, pos = strfind( str, '^%s+' );

        if pos then
            str = strsub( str, pos + 1 );
        end

        pos = strfind( str, '%s+$' );
        if pos then
            return strsub( str, 1, pos - 1 );
        end

        return str;
    end
end


return trim;

