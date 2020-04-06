#! /usr/bin/lua

require 'Test.More'

plan(6)

ok(subtest, 'subtest() should be exported to our namespace')
type_ok(subtest, 'function')

subtest('subtest with plan', function ()
        plan(2)
        ok(true, 'planned subtests should work')
        ok(true, '... and support more than one test')
end)
subtest('subtest without plan', function ()
        plan 'no_plan'
        ok(true, 'no_plan subtests should work')
        ok(true, '... and support more than one test')
        ok(true, '... no matter how many tests are run')
end)
subtest('subtest with implicit done_testing()', function ()
        ok(true, 'subtests with an implicit done testing should work')
        ok(true, '... and support more than one test')
        ok(true, '... no matter how many tests are run')
end)
subtest('subtest with explicit done_testing()', function ()
        ok(true, 'subtests with an explicit done testing should work')
        ok(true, '... and support more than one test')
        ok(true, '... no matter how many tests are run')
        done_testing()
end)

