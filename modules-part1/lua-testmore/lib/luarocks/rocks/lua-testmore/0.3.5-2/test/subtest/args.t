#! /usr/bin/lua

-- What happens when a subtest dies?

require 'Test.More'

local tb = require 'Test.Builder'.new()

local r, msg = pcall(function ()
                tb:subtest()
end)
nok(r)
like(msg, "subtest%(%)'s second argument must be a function")

r, msg = pcall(function ()
                tb:subtest('foo')
end)
nok(r)
like(msg, "subtest%(%)'s second argument must be a function")

tb:done_testing()

