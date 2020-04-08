#! /usr/bin/lua

require 'Test.More'
require 'Test.Builder.Tester'
require 'Test.LongString'
plan(2)

test_out "ok 1 - looks like Finnegans Wake"
is_string_nows([[
riverrun, past Eve and Adam's, from swerve of shore to bend
of bay, brings us by a commodius vicus of recirculation back to
Howth Castle and Environs.
]], "riverrun,pastEveandAdam's,fromswerveofshoretobendofbay,bringsusbyacommodiusvicusofrecirculationbacktoHowthCastleandEnvirons.",
    "looks like Finnegans Wake"
)
test_test "is_string_nows removes whitespace"

test_out "not ok 1 - non-ws differs"
test_fail(7)
test_diag [[after whitespace removal:]]
test_diag [[         got: "abc"]]
test_diag [[      length: 3]]
test_diag [[    expected: "abd"]]
test_diag [[      length: 3]]
test_diag [[    strings begin to differ at char 3]]
is_string_nows( "a b c", "abd", "non-ws differs" )
test_test "is_string_nows tests correctly"

