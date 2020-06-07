#! /usr/bin/lua

require 'Test.More'
require 'Test.Builder.Tester'
require 'Test.LongString'
plan(5)


test_out "ok 1 - foo matches foo"
like_string( "foo", 'foo', "foo matches foo" )
test_test "a small string matches"


test_out "not ok 1 - foo matches foo"
test_fail(4)
test_diag [[         got: "bar"]]
test_diag [[      length: 3]]
test_diag [[    doesn't match 'foo']]
like_string( "bar", 'foo', "foo matches foo" )
test_test "a small string doesn't match"


test_out "not ok 1 - foo matches foo"
test_fail(2)
test_diag "got value isn't a string : nil"
like_string( nil, 'foo', "foo matches foo" )
test_test "got nil"


test_out "not ok 1 - long string matches a*"
test_fail(5)
test_diag [[         got: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"...]]
test_diag [[      length: 100]]
test_diag [[    doesn't match '^a*$']]
local str = string.rep('a', 60) .. 'b' .. string.rep('a', 39)
like_string( str, '^a*$', "long string matches a*" )
test_test "a huge string doesn't match"


test_out "not ok 1 - foo doesn't match bar"
test_fail(4)
test_diag [[         got: "bar"]]
test_diag [[      length: 3]]
test_diag [[          matches 'bar']]
unlike_string( "bar", 'bar', "foo doesn't match bar" )
test_test "a small string matches while it shouldn't"

