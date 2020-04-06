#! /usr/bin/lua

require 'Test.More'

local c = require 'CBOR'

local unpack = table.unpack or unpack

local vectors = (loadfile(c.small_lua and 'test/appendix_a.32bits.vect' or 'test/appendix_a.vect'))()

local function unhex (s)
    local t = {}
    for v in s:gmatch'%x%x' do
        t[#t+1] = tonumber(v, 16)
    end
    return string.char(unpack(t))
end

local t = {}
for _, vector in ipairs(vectors) do
    local ref = vector.decoded
    if ref then
        local cbor = unhex(vector.hex)
        t[#t+1] = cbor
        local val = c.decode(cbor)
        if type(val) == 'table' then
            is_deeply(val, ref, "decode hex " .. vector.hex)
            is_deeply(c.decode(c.encode(val)), val, "decode/encode hex " .. vector.hex)
        else
            if c.long_double and type(val) == 'number' then
                skip("long double", 1)
            else
                is(val, ref, "decode hex " .. vector.hex)
            end
            is(c.decode(c.encode(val)), val, "decode/encode hex " .. vector.hex)
        end
    end
end

local encoded = table.concat(t)
local f = io.open('stream.cbor', 'w')
f:write(encoded)
f:close()
local r, ltn12 = pcall(require, 'ltn12')        -- from LuaSocket
if not r then
    diag "ltn12.source.file emulated"
    ltn12 = { source = {} }

    function ltn12.source.file (handle)
        if handle then
            return function ()
                local chunk = handle:read(1)
                if not chunk then
                    handle:close()
                end
                return chunk
            end
        else return function ()
                return nil, "unable to open file"
            end
        end
    end
end
local i = 1
f = io.open('stream.cbor', 'r')
local s = ltn12.source.file(f)
for _, val in c.decoder(s) do
    while not vectors[i].decoded do
        i = i + 1
    end
    local ref = vectors[i].decoded
    if type(val) == 'table' then
        is_deeply(val, ref, "decode hex " .. vectors[i].hex)
    else
        if c.long_double and type(val) == 'number' then
            skip("long double", 1)
        else
            is(val, ref, "decode hex " .. vectors[i].hex)
        end
    end
    i = i + 1
end
os.remove 'stream.cbor'  -- clean up

diag("set_string'byte_string'")
c.set_string'byte_string'
for _, vector in ipairs(vectors) do
    local ref = vector.decoded
    if ref then
        local cbor = unhex(vector.hex)
        local val = c.decode(cbor)
        if type(val) == 'table' then
            is_deeply(c.decode(c.encode(val)), val, "decode/encode hex " .. vector.hex)
        else
            is(c.decode(c.encode(val)), val, "decode/encode hex " .. vector.hex)
        end
    end
end
c.set_string'text_string'

diag("set_array'with_hole'")
c.set_array'with_hole'
for _, vector in ipairs(vectors) do
    local ref = vector.decoded
    if ref then
        local cbor = unhex(vector.hex)
        local val = c.decode(cbor)
        if type(val) == 'table' then
            is_deeply(c.decode(c.encode(val)), val, "decode/encode hex " .. vector.hex)
        else
            is(c.decode(c.encode(val)), val, "decode/encode hex " .. vector.hex)
        end
    end
end
diag("set_array'always_as_map'")
c.set_array'always_as_map'
for _, vector in ipairs(vectors) do
    local ref = vector.decoded
    if ref then
        local cbor = unhex(vector.hex)
        local val = c.decode(cbor)
        if type(val) == 'table' then
            is_deeply(c.decode(c.encode(val)), val, "decode/encode hex " .. vector.hex)
        else
            is(c.decode(c.encode(val)), val, "decode/encode hex " .. vector.hex)
        end
    end
end
c.set_array'without_hole'

done_testing()
