#!/usr/bin/env lua

local export  = { }

local debug    = debug
local getinfo  = debug.getinfo
local rawequal = rawequal
local require  = require

local function required ( )
    local frame = 3
    local about = getinfo (3)

    while about do
        if rawequal (about.func, require) then
            return true
        end

        frame = frame + 1
        about = getinfo (frame)
    end

    return false
end

-----------------------------------------------------------

function export.script ( )
    return not export.module ( )
end

function export.module ( )
    return required ( )
end

if export.script ( ) then
    error "You should not pass here through the script mode!"

else
    return export
end

-- END --
