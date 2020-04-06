#! /usr/bin/lua

require 'Test.More'
require 'Test.Builder.Tester'
require 'Test.LongString'
plan(4)


-- In there
test_out "ok 1 - What's in my dog food?"
contains_string( "Dog food", "foo", "What's in my dog food?" )
test_test "a small string matches"


-- Not in there
test_out "not ok 1 - Any nachos?"
test_fail(5)
test_diag [[    searched: "Dog food"]]
test_diag [[  can't find: "Nachos"]]
test_diag [[        LCSS: "o"]]
test_diag [[LCSS context: "Dog food"]]
contains_string( "Dog food", "Nachos", "Any nachos?" )
test_test "Substring doesn't match"


-- Source string nil
test_out "not ok 1 - Look inside nil"
test_fail(2)
test_diag "String to look in isn't a string"
contains_string( nil, "Orange everything", "Look inside nil")
test_test "Source string nil fails"


-- Searching string nil
test_out "not ok 1 - Look for nil"
test_fail(2)
test_diag "String to look for isn't a string"
contains_string( '"Mesh" is not a color', nil, "Look for nil" )
test_test "Substring nil fails"

