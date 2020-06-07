#!/usr/bin/env lua

local CodeGen = require 'CodeGen'

require 'Test.More'

plan(21)

local tmpl = CodeGen{
    code = [[print("${hello}, ${_guy1; format=upper}");]],
    upper = string.upper,
    hello = "Hello",
    _guy1 = "you",
}
is( tmpl 'code', [[print("Hello, YOU");]], "scalar attributes" )
tmpl.hello = "Hi"
local res, msg = tmpl 'code'
is( res, [[print("Hi, YOU");]] )
is( msg, nil, "no error" )

tmpl = CodeGen()
tmpl.a = { 'abc', 'def', 'hij' }
tmpl.upper1 = string.upper
tmpl.upper2 = function (str) return string.upper(str) end
tmpl.upper3 = function (str) return str:upper() end
tmpl.code = [[print(${a})]]
is( tmpl 'code', [[print(abcdefhij)]], "array" )
tmpl.code = [[print(${a; separator=', '})]]
is( tmpl 'code', [[print(abc, def, hij)]], "array with sep" )
tmpl.code = [[print(${a; separator = "\44\32" })]]
is( tmpl 'code', [[print(abc, def, hij)]], "array with sep" )
tmpl.code = [[print(${a; format=upper1 })]]
is( tmpl 'code', [[print(ABCDEFHIJ)]], "array" )
tmpl.code = [[print(${a; separator='\044\032'; format=upper2})]]
is( tmpl 'code', [[print(ABC, DEF, HIJ)]], "array with sep & format" )
eq_array( tmpl.a, { 'abc', 'def', 'hij' }, "don't alter the original table" )
tmpl.code = [[print(${a; separator = ", " ; format = upper3 })]]
is( tmpl 'code', [[print(ABC, DEF, HIJ)]], "array with sep & format" )
eq_array( tmpl.a, { 'abc', 'def', 'hij' }, "don't alter the original table" )

tmpl = CodeGen{
    code = [[print("${data.hello}, ${data.people.guy}");]],
    data = {
        hello = "Hello",
        people = {
            guy = "you",
        },
    },
}
is( tmpl 'code', [[print("Hello, you");]], "complex attr" )
tmpl.data.hello = "Hi"
is( tmpl 'code', [[print("Hi, you");]] )

tmpl.code = [[print("${hello}, ${people.guy}");]]
res, msg = tmpl 'code'
is( res, [[print(", ");]], "missing attr" )
is( msg, "code:1: people.guy is invalid" )

tmpl.code = [[print("${hello-people}");]]
res, msg = tmpl 'code'
is( res, [[print("${hello-people}");]], "no match" )
is( msg, "code:1: ${hello-people} does not match" )

tmpl.code = [[print("${ hello }");]]
res, msg = tmpl 'code'
is( res, [[print("${ hello }");]], "no match" )
is( msg, "code:1: ${ hello } does not match" )

tmpl.code = [[print("${hello; format=lower }");]]
res, msg = tmpl 'code'
is( res, [[print("${hello; format=lower }");]], "no formatter" )
is( msg, "code:1: lower is not a formatter" )

