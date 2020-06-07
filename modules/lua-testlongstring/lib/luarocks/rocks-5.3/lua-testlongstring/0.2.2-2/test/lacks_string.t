#! /usr/bin/lua

require 'Test.More'
require 'Test.Builder.Tester'
require 'Test.LongString'
plan(4)


-- In there
test_out "ok 1 - Any chocolate in my peanut butter?"
lacks_string( "Reese's Peanut Butter Cups", "Chocolate", "Any chocolate in my peanut butter?" )
test_test "Lacking"


-- Not in there
test_out "not ok 1 - Any peanut butter in my chocolate?"
test_fail(4)
test_diag [[    searched: "Reese's Peanut Butter Cups"]]
test_diag [[   and found: "Peanut Butter"]]
test_diag [[ at position: 9 (line 1 column 9)]]
lacks_string( "Reese's Peanut Butter Cups", "Peanut Butter", "Any peanut butter in my chocolate?" )
test_test "Not lacking"


-- Source string nil
test_out "not ok 1 - Look inside nil"
test_fail(2)
test_diag "String to look in isn't a string"
lacks_string( nil, "Orange everything", "Look inside nil" )
test_test "Source string nil fails"


-- Searching string nil
test_out "not ok 1 - Look for nil"
test_fail(2)
test_diag "String to look for isn't a string"
lacks_string( '"Fishnet" is not a color', nil, "Look for nil" )
test_test "Substring nil fails"

