#! /usr/bin/lua

require 'Test.More'

plan(12)

local tb = require 'Test.Builder.NoOutput'.create()
tb:plan(7)
tb:failure_output(tb:output())
for i = 1, 3 do
    tb:ok(i, "We're on " .. tostring(i))
    tb:diag("We ran " .. tostring(i))
end
do
    local indented = tb:child()
    indented:plan'no_plan'
    indented:ok(true, "We're on 1")
    indented:diag("We ran 4.1")
    indented:ok(true, "We're on 2")
    indented:diag("We ran 4.2"
            .. "\n still 4.2")
    indented:ok(true, "We're on 3" )
    indented:diag("We ran 4.3"
            .. "\n still 4.3\n"
            .. "\n still 4.3\n")
    indented:done_testing()
    indented:diag("We ran 4")
    indented:finalize()
end
for i = 7, 9 do
    tb:ok(i, "We're on " .. tostring(i))
end
is(tb:read'out', [[
1..7
ok 1 - We're on 1
# We ran 1
ok 2 - We're on 2
# We ran 2
ok 3 - We're on 3
# We ran 3
    ok 1 - We're on 1
    # We ran 4.1
    ok 2 - We're on 2
    # We ran 4.2
    #  still 4.2
    ok 3 - We're on 3
    # We ran 4.3
    #  still 4.3
    #
    #  still 4.3
    1..3
    # We ran 4
ok 4
ok 5 - We're on 7
ok 6 - We're on 8
ok 7 - We're on 9
]], 'Output should nest properly')

tb = require 'Test.Builder.NoOutput'.create()
tb:plan'no_plan'
tb:failure_output(tb:output())
for i = 1, 1 do
    tb:ok(true, "We're on " .. tostring(i))
    tb:diag("We ran " .. tostring(i))
end
do
    local indented = tb:child()
    indented:plan'no_plan'
    indented:ok(true, "We're on 1")
    do
        local indented2 = indented:child('with name')
        indented2:plan(2)
        indented2:ok(true, "We're on 2.1")
        indented2:ok(true, "We're on 2.1")
        indented2:done_testing()
        indented2:finalize()
    end
    indented:ok(true, 'after child')
    indented:done_testing()
    indented:finalize()
end
for i = 7, 7 do
    tb:ok(true, "We're on " .. tostring(i))
    tb:diag("We ran " .. tostring(i))
end
tb:done_testing()

is(tb:read'out', [[
ok 1 - We're on 1
# We ran 1
    ok 1 - We're on 1
        1..2
        ok 1 - We're on 2.1
        ok 2 - We're on 2.1
    ok 2 - with name
    ok 3 - after child
    1..3
ok 2
ok 3 - We're on 7
# We ran 7
1..3
]], 'We should allow arbitrary nesting')

tb = require 'Test.Builder.NoOutput'.create()
do
    local child = tb:child('expected to fail')
    child:plan(3)
    child:ok(true)
    child:ok(false)
    child:ok(true)
    child:done_testing()
    child:finalize()
end
do
    local child = tb:child('expected to pass')
    child:plan(3)
    child:ok(true)
    child:ok(true)
    child:ok(true)
    child:done_testing()
    child:finalize()
end

is(tb:read'out', [[
    1..3
    ok 1
    not ok 2
    ok 3
not ok 1 - expected to fail
    1..3
    ok 1
    ok 2
    ok 3
ok 2 - expected to pass
]], 'Previous child failures should not force subsequent failures')

tb = require 'Test.Builder.NoOutput'.create()
local child = tb:child('one')
is(child:output(), tb:output(), "The child should copy the filehandle")
is(child:failure_output(), tb:failure_output())
is(child:todo_output(), tb:todo_output())

tb = require 'Test.Builder.NoOutput'.create()
child = tb:child('one')
is(child.parent, tb, 'the parent of the child')
nok(tb.parent, '... but top level builders should not have parents')

tb = require 'Test.Builder.NoOutput'.create()
do
    child = tb:child('skippy says he loves you')
    local r, msg = pcall(function ()
                                child:skip_all'cuz I said so'
                         end)
    nok(r)
    is(msg, "skip_all in child")
end

tb = require 'Test.Builder.NoOutput'.create()
tb:plan(1)
child = tb:child()
child:plan(1)
child:todo('message', 1)
child:ok(false)
child:done_testing()
child:finalize()
is(tb:read'out', [[
1..1
    1..1
    not ok 1 # TODO message
ok 1
]], 'TODO tests should not make the parent test fail')

tb = require 'Test.Builder.NoOutput'.create()
tb:plan(1)
child = tb:child("Child")
child:finalize()
is(tb:read'out', [[
1..1
not ok 1 - No tests run for subtest "Child"
]], 'Not running subtests should make the parent test fail')
