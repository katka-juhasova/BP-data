#! /usr/bin/lua

-- Test the idiom of running another test file as a subtest.

require 'Test.More'

pass "First"

local file = "../test/subtest/for_loadfile_t.test"

subtest(file, loadfile(file))

pass "Last"

done_testing(3)
