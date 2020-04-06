local r2cmake = require 'rockspec2cmake'
local pl = require "pl.import_into"()

local function load_rockspec(filename)
    local fd, err = io.open(filename)
    if not fd then
        return nil
    end
    local str, err = fd:read("*all")
    fd:close()
    if not str then
        return nil
    end

    -- Remove "#!/usr/bin lua" like lines since they are not valid Lua
    -- but seem to be present in rockspec files
    str = str:gsub("^#![^\n]*\n", "")
    str = str:gsub("\n#![^\n]*\n", "")
    return pl.pretty.load(str)
end

if #arg ~= 1 then
    print("Usage: lua rockspec2cmake.lua rockspec_file")
else
    local rockspec = load_rockspec(arg[1])

    if not rockspec then
        print("Failed to load rockspec file (" .. arg[1] .. ")")
    else
        local cmake, err = r2cmake.process_rockspec(rockspec)

        if not cmake then
            print("Fatal error, cmake not generated: " .. err)
        else
            print(cmake)
        end
     end
end
