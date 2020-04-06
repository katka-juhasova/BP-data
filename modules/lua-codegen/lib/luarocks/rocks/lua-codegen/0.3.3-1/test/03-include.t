#!/usr/bin/env lua

local CodeGen = require 'CodeGen'

require 'Test.More'

plan(5)

local tmpl = CodeGen{
    outer = [[
begin
    ${inner()}
end
]],
    inner = [[print("${hello}");]],
    hello = "Hello, world!",
}
is( tmpl 'outer', [[
begin
    print("Hello, world!");
end
]] , "" )

tmpl.inner = 3.14
local res, msg = tmpl 'outer'
is( res, [[
begin
    ${inner()}
end
]] , "not a template" )
is( msg, "outer:2: inner is not a template" )

tmpl = CodeGen{
    top = [[
${outer()}
]],
    outer = [[
begin
    ${inner()}
end
]],
    inner = [[print("${outer()}");]],
}
res, msg = tmpl 'top'
is( res, [[
begin
    print("${outer()}");
end
]], "cyclic call" )
is( msg, "inner:1: cyclic call of outer" )
