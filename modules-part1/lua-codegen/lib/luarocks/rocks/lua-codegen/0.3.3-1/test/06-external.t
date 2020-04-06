#!/usr/bin/env lua

CodeGen = require 'CodeGen'

require 'Test.More'

plan(1)

local tmpl = dofile '../test/tmpl.lua'
tmpl.data = {
    { name = 'key1', value = 1 },
    { name = 'key2', value = 2 },
    { name = 'key3', value = 3 },
}
is( tmpl 'top', [[
begin
        print("key1 = 1");
        print("key2 = 2");
        print("key3 = 3");
end
]] , "external" )
