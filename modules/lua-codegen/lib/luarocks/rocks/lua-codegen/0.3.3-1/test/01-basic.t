#!/usr/bin/env lua

local CodeGen = require 'CodeGen'

require 'Test.More'

plan(8)

local tmpl = CodeGen()
type_ok( tmpl, 'table', "new CodeGen" )
tmpl.a = 'some text'
is( tmpl 'a', 'some text', "eval 'a'" )

tmpl = CodeGen{
    pi = 3.14159,
    str = 'some text',
}
type_ok( tmpl, 'table', "new CodeGen" )
tmpl.pi = 3.14
is( tmpl 'str', 'some text', "eval 'str'" )
is( tmpl 'pi', '3.14', "eval 'pi'" )
isnt( tmpl 'pi', 3.14 )
is( tmpl 'unk', '', "unknown gives an empty string" )

is( tostring(tmpl), 'CodeGen', "__tostring" )
