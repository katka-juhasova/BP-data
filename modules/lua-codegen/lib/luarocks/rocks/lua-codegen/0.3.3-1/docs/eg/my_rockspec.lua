CodeGen = require 'CodeGen'

local rs = dofile 'my_rockspec.tmpl'
rs.name = 'lua-CodeGen'
rs.version = '0.1.0'
rs.revision = 1
rs.md5 = 'XxX'
rs.desc.summary = "a template engine"
rs.dependencies = {
    { name = 'lua', version = 5.1 },
    { name = 'lua-testmore', version = '0.2.1' },
}
print(rs 'rockspec')
