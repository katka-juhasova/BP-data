#! /usr/bin/lua

require 'Test.More'
plan(4)

local why = "Just testing the skip_rest interface."

if false then
    skip_rest("We're not skipping")
else
    pass "not skipped in this branch"
    pass "not skipped again"
end

if true then
    skip_rest(why)
else
    fail "Deliberate failure"
    fail "And again"
end

