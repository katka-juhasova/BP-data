#!/usr/bin/env lua

local CodeGen = require 'CodeGen'

require 'Test.More'

plan(2)

local tmpl = CodeGen {    -- instanciation
    tarball = "${name}-${version}.tar.gz",
    name = 'lua',
}
tmpl.version = 5.1
local output = tmpl 'tarball'     -- interpolation
is( output, 'lua-5.1.tar.gz', "for the impatient" )


tmpl = CodeGen {
    call = "${name}(${parameters; separator=', '});",
}
tmpl.name = 'print'
tmpl.parameters = { 1, 2, 3 }
output = tmpl 'call'
is( output, 'print(1, 2, 3);', "attribute reference" )


