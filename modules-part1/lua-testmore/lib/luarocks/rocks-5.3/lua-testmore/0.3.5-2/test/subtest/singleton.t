#! /usr/bin/lua

require 'Test.More'

plan(3)

local tb = require 'Test.Builder'.new()
local function singleton_ok (val, name)
    tb:ok(val, name)
end

ok(true, 'TB top level')
subtest('doing a subtest', function ()
    plan(4)
    ok(true, 'first test in subtest')
    singleton_ok(true, 'this should not fail')
    ok(true, 'second test in subtest')
    singleton_ok(true, 'this should not fail')
end)
ok(true, 'left subtest')

