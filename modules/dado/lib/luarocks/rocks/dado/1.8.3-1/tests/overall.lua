#!/usr/local/bin/lua

local path = arg[0]:sub (1, arg[0]:find"/overall")
if arg[0]:find"/overall" == nil then
	path = ""
end

io.write("Testing ")
local dado = require"dado"
io.write(dado._VERSION)
io.write(" in ")
io.write(_VERSION)
io.write("\n")

io.write("table.extra ...")
assert(loadfile(path.."ttable.extra.lua"))()
io.write("sql ...")
assert(loadfile(path.."tsql.lua"))()
io.write("dado ...")
assert(loadfile(path.."tdado.lua"))(...)
io.write("dbobj ...")
assert(loadfile(path.."tdbobj.lua"))()
