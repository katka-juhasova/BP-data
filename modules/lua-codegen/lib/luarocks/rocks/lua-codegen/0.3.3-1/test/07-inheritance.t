#!/usr/bin/env lua

local CodeGen = require 'CodeGen'

require 'Test.More'

plan(2)

local tmpl1 = CodeGen {
    _a = [[ ${a} ${_b()} ]],
    _b = [[ (${b}) ]],
    a = 'print',
    b = 1,
}

is( tmpl1 '_a', ' print  (1)  ' )

local tmpl2 = CodeGen({
    _b = [[ [${c}] ]],
    a = 'call',
}, tmpl1, { c = 2 })

is( tmpl2 '_a', ' call  [2]  ' )

