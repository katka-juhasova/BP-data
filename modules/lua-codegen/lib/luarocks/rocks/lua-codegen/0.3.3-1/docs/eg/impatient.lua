local CodeGen = require 'CodeGen'

tmpl = CodeGen {    -- instanciation
    tarball = "${name}-${version}.tar.gz",
    name = 'lua',
}
tmpl.version = 5.1
output = tmpl 'tarball'     -- interpolation
print(output) --> lua-5.1.tar.gz
