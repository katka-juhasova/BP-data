#!/usr/bin/env lua

-- Lua SMAZ tests
--
-- Vladimir Shaykovskiy <oik741@gmail.com>
--

local smaz = require "smaz"

local strings_to_test = {
    "This is a small string",
    "foobar",
    "the end",
    "not-a-g00d-Exampl333",
    "Smaz is a simple compression library",
    "Nothing is more difficult, and therefore more precious, than to be able to decide",
    "this is an example of what works very well with smaz",
    "1000 numbers 2000 will 10 20 30 compress very little",
    "and now a few italian sentences:",
    "Nel mezzo del cammin di nostra vita, mi ritrovai in una selva oscura",
    "Mi illumino di immenso",
    "L'autore di questa libreria vive in Sicilia",
    "try it against urls",
    "http://google.com",
    "http://programming.reddit.com",
    "http://github.com/antirez/smaz/tree/master",
    "/media/hdb1/music/Alben/The Bla",
    "some non-ascii symbols £©½Ω",
}

local function test_smaz(data)

    local compressed_data = smaz.compress(data)

    local comp_level = 100 - ((100 * #compressed_data) / #data)
    local decompressed_data, err = smaz.decompress(compressed_data)

    if not decompressed_data then
        return nil, err
    end

    if data ~= decompressed_data then
        return nil, "Orig and decompressed data doesn't match"
    end

    return comp_level, err
end


print("------------------------------------------------------------")
print("Testing smaz...")
print("------------------------------------------------------------\n")

for _, v in ipairs(strings_to_test) do
    io.write("String \"" .. v .. "\" ")
    local comp_level, err = test_smaz(v)

    if not comp_level then
        print("failed to compress/decompress, reason: " .. err)
    end

    if comp_level < 0 then
        print("enlarged by " .. string.format("%.2f", -comp_level) .. "%")
    else
        print("decreased by " .. string.format("%.2f", comp_level) .. "%")
    end
end

