#! /usr/bin/lua

require 'Test.More'
require 'Test.Builder.Tester'
require 'Test.LongString'
plan(8)

test_out "ok 1 - foo is foo"
is_string( "foo", "foo", "foo is foo" )
test_test "two small strings equal"


test_out "not ok 1 - foo is foo"
test_fail(6)
test_diag [[         got: "bar"]]
test_diag [[      length: 3]]
test_diag [[    expected: "foo"]]
test_diag [[      length: 3]]
test_diag [[    strings begin to differ at char 1 (line 1 column 1)]]
is_string( "bar", "foo", "foo is foo" )
test_test "two small strings different"


test_out "not ok 1 - foo is foo"
test_fail(2)
test_diag "got value isn't a string : nil"
is_string( nil, "foo", "foo is foo" )
test_test "got nil, expected small string"


test_out "not ok 1 - foo is foo"
test_fail(2)
test_diag "expected value isn't a string : nil"
is_string( "foo", nil, "foo is foo" )
test_test "expected nil, got small string"


test_out "not ok 1 - long binary strings"
test_fail(6)
test_diag [[         got: "This is a long string that will be truncated by th"...]]
test_diag [[      length: 70]]
test_diag [[    expected: "\000\001foo\010bar"]]
test_diag [[      length: 9]]
test_diag [[    strings begin to differ at char 1 (line 1 column 1)]]
is_string(
    "This is a long string that will be truncated by the display() function",
    "\0\001foo\nbar",
    "long binary strings"
)
test_test "display of long strings and of control chars"


test_out "not ok 1 - spelling"
test_fail(6)
test_diag [[         got: "Element"]]
test_diag [[      length: 7]]
test_diag [[    expected: "El\233ment"]]
test_diag [[      length: 7]]
test_diag [[    strings begin to differ at char 3 (line 1 column 3)]]
is_string(
    "Element",
    "Elément",
    "spelling"
)
test_test "Escape high-ascii chars"


test_out "not ok 1 - foo\\nfoo is foo\\nfoo"
test_fail(6)
test_diag [[         got: "foo\010foo"]]
test_diag [[      length: 7]]
test_diag [[    expected: "foo\010fpo"]]
test_diag [[      length: 7]]
test_diag [[    strings begin to differ at char 6 (line 2 column 2)]]
is_string( "foo\nfoo", "foo\nfpo", "foo\\nfoo is foo\\nfoo" )
test_test "Count correctly prefix with multiline strings"


test_out "not ok 1 - this isn't Ulysses"
test_fail(6)
test_diag [[         got: ..."he bowl aloft and intoned:\010--Introibo ad altare de"...]]
test_diag [[      length: 275]]
test_diag [[    expected: ..."he bowl alift and intoned:\010--Introibo ad altare de"...]]
test_diag [[      length: 275]]
test_diag [[    strings begin to differ at char 233 (line 4 column 17)]]
is_string( [[
Stately, plump Buck Mulligan came from the stairhead, bearing a bowl of
lather on which a mirror and a razor lay crossed. A yellow dressinggown,
ungirdled, was sustained gently behind him by the mild morning air. He
held the bowl aloft and intoned:
--Introibo ad altare dei.
]], [[
Stately, plump Buck Mulligan came from the stairhead, bearing a bowl of
lather on which a mirror and a razor lay crossed. A yellow dressinggown,
ungirdled, was sustained gently behind him by the mild morning air. He
held the bowl alift and intoned:
--Introibo ad altare dei.
]], "this isn't Ulysses" )
test_test "Display offset in diagnostics"

