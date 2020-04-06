--[[

  Copyright (C) 2014 Masatoshi Teruya

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

  lib/6749.lua
  Created by Masatoshi Teruya on 14/12/11.

--]]

--
-- https://www.ietf.org/rfc/rfc6749.txt
-- Appendix A.  Augmented Backus-Naur Form (ABNF) Syntax
--
-- NQCHAR     = %x21 / %x23-5B / %x5D-7E
--              ! # $ % & ' ( ) * + , - . / 0-9 : ; < = > ? @ A-Z [ ] ^ _ `
--              a-z { | } ~
--
local INVALID_NQCHAR = "[^%w!#$%%&'()*+,./:;<=>?@[%]^_`{|}~-]";


--
-- A.4.  "scope" Syntax
-- scope-token = 1*NQCHAR
--

--- isScopeToken
-- @param str
-- @return str
local function isScopeToken( str )
    if type( str ) ~= 'string' or #str < 1 then
        return nil;
    end

    return not str:find( INVALID_NQCHAR ) and str or nil;
end


return {
    isScopeToken = isScopeToken
};

