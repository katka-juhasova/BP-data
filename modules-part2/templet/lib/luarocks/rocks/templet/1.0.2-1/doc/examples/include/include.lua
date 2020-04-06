local templet = require("templet")

local function template(filename, env)
  local function include(filename)
    local filename, err = package.searchpath(filename, package.path)
    if not filename then return error(err) end
    local template = templet.loadfile(filename)
    return template(env)
  end
  env = setmetatable({include = include}, {__index = env})
  return include(filename)
end

io.write(template("test.main", {hello = "Ciao", world = "mondo"}))
