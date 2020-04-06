#! /usr/bin/lua

-- A subtest without a plan implicitly calls "done_testing"

require 'Test.More'

pass "Before"

subtest('basic', function ()
    pass "Inside sub test"
end)

subtest('with done', function ()
    pass 'This has done_testing'
    done_testing()
end)

subtest('with plan', function ()
    plan(1)
    pass 'I have a plan, Batman!'
end)

subtest('skipping', function ()
    skip_all 'Skipping'
    fail 'Shouldnt see me!'
end)

pass "After"

done_testing()
