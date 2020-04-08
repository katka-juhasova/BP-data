--[[
    Copyright 2016 Kenny Shields <mail@kennyshields.net>

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
--]]

local lib = {}

local in_comment = false
local comment_multiline = false
local comment_end_pattern = false

-- table containing patterns of single/multiline comment tokens
local comment_patterns = {
    multiline = {
        ["--[["] = "]]",
        ["/*"] = "*/"
    },
    single = {
        "--"
    }
}

-- table containing collected token data
local collected = {}

-- misc token variables
local token_pattern = "@([a-z]*)"
local token_table = false
local token_current = false

local function trim(str)

    return (str:gsub("^%s*(.-)%s*$", "%1"))

end

local function findSingleLineComment(str)

    for k, v in pairs(comment_patterns.single) do
        if str:sub(1, v:len()) == v then
            return trim(str:sub(v:len() + 1))
        end
    end

    return false

end

local function checkComment(str)

    if not in_comment then
        for k, v in pairs(comment_patterns.multiline) do
            if str:sub(1, k:len()) == k then
                in_comment = true
                if str:sub(-v:len()) == v then
                    return trim(str:sub(k:len() + 1, -(v:len() + 1)))
                else
                    comment_multiline = true
                    comment_end_pattern = v
                    return trim(str:sub(k:len() + 1))
                end
            end
        end
        local str_new = findSingleLineComment(str)
        if str_new then
            in_comment = true
            return str_new
        end
    else
        if not comment_multiline then
            local str_new = findSingleLineComment(str)
            if str_new then
                return str_new
            else
                in_comment = false
            end
        else
            if str:sub(-comment_end_pattern:len()) == comment_end_pattern then
                in_comment = false
                comment_multiline = false
                comment_end_pattern = false
            end
        end
    end

    return str

end

local function checkNamed(str)

    -- find any named items in the string
    local pattern = "(%[([a-zA-Z0-9_ ]*):([a-zA-Z0-9_ ]*)%])"
    for match in str:gmatch(pattern) do
        -- add the named items to the sub token table
        local name, contents = match:match(pattern:sub(2, -2))
        token_table[token_current][#token_table[token_current]][name] = contents
    end

    -- remove all named items from the string
    str = trim(str:gsub(pattern, ""))

    -- append any remaining text to the sub token's default string
    local text = token_table[token_current][#token_table[token_current]]._default
    if text ~= "" then
        str = " " .. str
    end
    token_table[token_current][#token_table[token_current]]._default = text .. str

end

local function parseLine(line)

    -- check line comment
    line = checkComment(line)
    if in_comment then
        -- check for a token at the start of the line
        local token = line:match(token_pattern)
        if token and line:find(token) == 2 then
            token_current = token
            -- remove the token from the line string
            line = trim(line:sub(token:len() + 2))
            if not token_table then
                if not collected[token_current] then
                    collected[token_current] = {{}}
                else
                    table.insert(collected[token_current], {})
                end
                -- the token table will be used to store all future sub tokens until
                -- the parent token is closed
                token_table = collected[token_current][#collected[token_current]]
            else
                if token_current == "end" then
                    -- reset token variables if the parent token has been closed
                    token_table = false
                    token_current = false
                else
                    -- create table for sub token and check the line string for any
                    -- named items
                    if not token_table[token_current] then
                        token_table[token_current] = {{_default = ""}}
                    else
                        table.insert(token_table[token_current], {_default = ""})
                    end
                    checkNamed(line)
                end
            end
        else
            if token_current and line ~= "" then
                checkNamed(line)
            end
        end
    end

end

function lib.init(config)

    -- reset variables
    in_comment = false
    comment_multiline = false
    comment_end_pattern = false
    token_table = false
    token_current = false
    collected = {}

    local path
    local temp = false
    if config.path then
        path = config.path
    elseif config.text then
        temp = true
        path = os.tmpname()
        local file = io.open(path, "w")
        if file then
            file:write(config.text)
            file:close()
        end
    else
        return false
    end

    if config.comment_patterns then
        if config.replace_comment_patterns then
            comment_patterns = config.comment_patterns
        else
            for k, v in pairs(config.comment_patterns.multiline) do
                comment_patterns.multiline[k] = v
            end
            for k, v in ipairs(config.comment_patterns.single) do
                table.insert(comment_patterns.single, v)
            end
        end
    end

    if config.token_pattern then
        token_pattern = config.token_pattern
    end

    for line in io.lines(path) do
        parseLine(trim(line))
    end

    if temp then
        os.remove(path)
    end

    return collected

end

return lib
