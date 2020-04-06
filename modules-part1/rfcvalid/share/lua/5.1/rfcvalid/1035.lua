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

  lib/1035.lua
  Created by Masatoshi Teruya on 17/08/05.

--]]

-- modules
local isUInt8 = require('rfcvalid.util').isUInt8;
local type = type;
local tonumber = tonumber;
local strsub = string.sub;
local strfind = string.find;
local strbyte = string.byte;
-- constants
local HYPHEN = string.byte('-');


--- isHostname
-- @param str
-- @return str
local function isHostname( str )
    if type( str ) == 'string' and #str > 0 and #str <= 253 then
        local labels = {};
        local idx = 0;
        local cur = 1;
        local head = strfind( str, '.', cur, true );

        -- not FQDN
        if not head then
            -- invalid label format
            if strfind( str, '[^%w-]' ) then
                return nil;
            end

            return str;
        end

        while head do
            local label = strsub( str, cur, head - 1 );
            local len = #label;

            -- label length must be 1-63
            -- first byte and last byte must not be hyphen
            -- label contains must be only alnum and hyphens
            if len == 0 or len > 63 or
               strbyte( label, 1 ) == HYPHEN or
               strbyte( label, len ) == HYPHEN or
               strfind( label, '[^%w-]' ) then
                -- invalid label format
                return nil;
            end

            idx = idx + 1;
            labels[idx] = label;

            -- find next
            cur = head + 1;
            head = strfind( str, '.', cur, true );
        end

        idx = idx + 1;
        labels[idx] = strsub( str, cur );

        -- labels must has least 2 segment
        if #labels > 1 then
            -- check IPv4 labels
            if #labels == 4 and #labels[1] <= 3 and
               strfind( labels[1], '^%d$+' ) then
                if isUInt8( tonumber( labels[1] ) ) and
                   strfind( labels[2], '^%d$+' ) and
                   isUInt8( tonumber( labels[2] ) ) and
                   strfind( labels[3], '^%d$+' ) and
                   isUInt8( tonumber( labels[3] ) ) and
                   strfind( labels[4], '^%d$+' ) and
                   isUInt8( tonumber( labels[4] ) ) then
                    return str;
                end
            -- hostname
            else
                return str;
            end
        end
    end

    return nil;
end


return {
    isHostname = isHostname
};

