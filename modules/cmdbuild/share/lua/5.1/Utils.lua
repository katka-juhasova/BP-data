--- Common utilities found in internet
-- @module Utils
-- @author lua community
-- @copyright public domain
-- @release $Id: deb58d6750eefc7330018c2b23c87c9a8bc5c98d $
-- vim: ts=2 tabstop=2 shiftwidth=2 expandtab
-- vim: retab 

local cjson = require 'cjson'

local Utils = {}

function Utils.isempty(s)
    return (type(s) == "table" and next(s) == nil) or s == nil or s == ''
end

function Utils.isin(tab, what)
    if Utils.isempty(tab) then
        return false
    end

    for i = 1, #tab do
        if tab[i] == what then
            return true
        end
    end

    return false
end

function Utils.int2bytes(num, width)
    local function _n2b(width, num, rem)
        rem = rem * 256
        if width == 0 then return rem end
        return rem, _n2b(width - 1, math.modf(num / 256))
    end

    return string.char(_n2b(width - 1, math.modf(num / 256)))
end

function Utils.istabempty(t)
    if type(t) == table and next(t) == nil then
        return true
    end
    return false
end

function Utils.isTabHasKey(tab, key)
    local result = false;
    if not Utils.istabempty(tab) then
        table.foreach(tab,
            function(key_, _)
                if (key_ == key) then
                    result = true;
                    return true;
                end
            end)
    end
    return result;
end

local tescape = {
    ['&'] = '&amp;',
    ['<'] = '&lt;',
    ['>'] = '&gt;',
    ['"'] = '&quot;',
    ["'"] = '&apos;',
}
local tunescape = {
    ['&amp;'] = '&',
    ['&lt;'] = '<',
    ['&gt;'] = '>',
    ['&quot;'] = '"',
    ['&apos;'] = "'",
}

------------------------------------------------------------------------
--  escape
--  Escape special characters
-- @param text - string to modify (string)
-- @return Modified string
------------------------------------------------------------------------
function Utils.escape(text)
    return (string.gsub(text, "([&<>'\"])", tescape))
end

------------------------------------------------------------------------
--  unescape
--  Unescape special characters
-- @param text - string to modify (string)
-- @return Modified string
------------------------------------------------------------------------
function Utils.unescape(text)
    return (string.gsub(text, "(&%a+%;)", tunescape))
end

-- LE int to bytes  written by Tom N Harris. 
-- http://lua-users.org/wiki/ReadWriteFormat
function Utils.int2bytes(num, width)
    local function _n2b(width, num, rem)
        rem = rem * 256
        if width == 0 then return rem end
        return rem, _n2b(width - 1, math.modf(num / 256))
    end

    return string.char(_n2b(width - 1, math.modf(num / 256)))
end

function Utils.zexpreplace(source, new)
    return source:gsub("{[%s]*[^:&|=}]*[:][^(]*", new)
end

function Utils.tsize(T)
    local count = 0
    for _ in pairs(T.Id) do
        count = count + 1
    end
    return count
end

------------------------------------------------------------------------
--  Utils.pretty
--  Format pretty JSON string
-- @param dt - jsonstring (string)
-- @param lf - {+DESCRIPTION+} ({+TYPE+})
-- @param id - {+DESCRIPTION+} ({+TYPE+})
-- @param ac - {+DESCRIPTION+} ({+TYPE+})
-- @param ec - {+DESCRIPTION+} ({+TYPE+})
-- @return pretty (string)
------------------------------------------------------------------------
function Utils.pretty(dt, lf, id, ac, ec)
    local s, e = (ec or cjson.encode)(dt)
    if not s then
        return s, e
    end
    lf, id, ac = lf or "\n", id or "\t", ac or " "
    local i, j, k, n, r, p, q = 1, 0, 0, #s, {}, nil, nil
    local al = string.sub(ac, -1) == "\n"
    for x = 1, n do
        local c = string.sub(s, x, x)
        if not q and (c == "{" or c == "[") then
            r[i] = p == ":" and table.concat { c, lf } or table.concat { string.rep(id, j), c, lf }
            j = j + 1
        elseif not q and (c == "}" or c == "]") then
            j = j - 1
            if p == "{" or p == "[" then
                i = i - 1
                r[i] = table.concat { string.rep(id, j), p, c }
            else
                r[i] = table.concat { lf, string.rep(id, j), c }
            end
        elseif not q and c == "," then
            r[i] = table.concat { c, lf }
            k = -1
        elseif not q and c == ":" then
            r[i] = table.concat { c, ac }
            if al then
                i = i + 1
                r[i] = string.rep(id, j)
            end
        else
            if c == '"' and p ~= "\\" then
                q = not q and true or nil
            end
            if j ~= k then
                r[i] = string.rep(id, j)
                i, k = i + 1, j
            end
            r[i] = c
        end
        p, i = c, i + 1
    end
    return table.concat(r)
end

return Utils;
