#!/usr/bin/env lua

--
--  see http://99-bottles-of-beer.net/
--

local CodeGen = require 'CodeGen'

require 'Test.More'

plan(1)

local function bootle (n)
    if n == 0 then
        return 'No more bottles of beer'
    elseif n == 1 then
        return '1 bottle of beer'
    else
        return tostring(n) .. ' bottles of beer'
    end
end

local function action (n)
    if n == 0 then
        return 'Go to the store and buy some more'
    else
        return 'Take one down and pass it around'
    end
end

local function populate ()
    local t = {}
    for i = 99, 0, -1 do
        table.insert(t, i)
    end
    return t
end

local tmpl = CodeGen {
    numbers = populate(),       -- { 99, 98, ..., 1, 0 }
    lyrics = [[
${numbers/stanza(); separator='\n'}
]],
    stanza = [[
${it; format=bootle} on the wall, ${it; format=bootle_lower}.
${it; format=action}, ${it; format=bootle_next} on the wall.
]],
    bootle = bootle,
    bootle_lower = function (n)
        return bootle(n):lower()
    end,
    bootle_next = function (n)
        return bootle((n == 0) and 99 or (n - 1)):lower()
    end,
    action = action,
}

local ref = io.open('../test/99-bottles-of-beer.txt'):read('*a')
is( tmpl 'lyrics', ref, "99 bottles of beer" )

