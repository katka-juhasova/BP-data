#!/usr/bin/env lua

local CodeGen = require 'CodeGen'

require 'Test.More'

plan(4)

local tmpl = CodeGen{
    outer = [[
begin
    ${data.locale?inner_fr()!inner_en()}
end
]],
    inner_en = [[print("Hello, ${data.guy}");]],
    inner_fr = [[print("Bonjour, ${data.guy}");]],
}

tmpl.data = {}
tmpl.data.locale = true
tmpl.data.guy = 'toi'
is( tmpl 'outer', [[
begin
    print("Bonjour, toi");
end
]] , "" )

tmpl.data.locale = false
tmpl.data.guy = 'you'
is( tmpl 'outer', [[
begin
    print("Hello, you");
end
]] , "" )

tmpl = CodeGen{
    outer = [[
begin
${data.guy?inner()}
end
]],
    inner = [[print("Hello, ${data.guy}");]],
}
tmpl.data = {}
tmpl.data.guy = 'you'
is( tmpl 'outer', [[
begin
print("Hello, you");
end
]] , "" )

tmpl.data.guy = nil
is( tmpl 'outer', [[
begin
end
]] , "" )
