local dir = require "pl.dir"
local file = require "pl.file"

local mod_path
local project_path

local function starts_with(str, start) return str:sub(1, #start) == start end

local function ends_with(str, ending) return ending == "" or str:sub(-(#ending)) == ending end

local function trim(s) return s:match "^()%s*$" and "" or s:match "^%s*(.*%S)" end

local function surround_with_quotes(str)
    str = trim(str)

    if not starts_with(str, '"') then str = '"' .. str end

    if not ends_with(str, '"') then str = str .. '"' end

    return str
end

local function remove_quotes(str)
    if starts_with(str, '"') then str = string.sub(str, 2) end

    if ends_with(str, '"') then str = string.sub(str, 1, -1) end

    return str
end

io.write("Please enter a path to the location where you would like to create the test project including the test project's name (the project folder will be created if it does not exist)\n")
project_path = trim(io.read())

if string.len(project_path) == 0 then
    print("Got empty project path. Exiting")
    os.exit()
end

project_path = remove_quotes(project_path)

io.write("Please enter your mod path (can be empty, you can still change it later in config.lua)\n")
mod_path = io.read()

if string.len(mod_path) > 0 then mod_path = surround_with_quotes(mod_path) end

io.write([[
Please select your chosen test framework by entering a number.
    1.) u-test
    2.) busted
    3.) No test framework
]])

local framework_choices = {[1] = "eaw.use_u_test()", [2] = "eaw.use_busted()"}

local framework = framework_choices[tonumber(io.read())]

local config_str = [[
eaw = require "eaw-abstraction-layer"
eaw.use_real_errors(true)
eaw.init(]] .. mod_path .. ")"

if framework then config_str = config_str .. "\n" .. framework end

dir.makepath(project_path .. "/AI/")
dir.makepath(project_path .. "/Evaluators/")
dir.makepath(project_path .. "/FreeStore/")
dir.makepath(project_path .. "/GameObject/")
dir.makepath(project_path .. "/Interventions/")
dir.makepath(project_path .. "/Library/")
dir.makepath(project_path .. "/Miscellaneous/")
dir.makepath(project_path .. "/Story/")
file.write(project_path .. "/config.lua", config_str)

if framework == framework_choices[2] then
    local busted_file = [[
return {
    default = {
        ROOT = {"."},
        ["helper"] = "config.lua",
        ["pattern"] = '_spec.lua',
        ["defer-print"] = true
    }
}
]]

    file.write(project_path .. "/.busted", busted_file)
end

print("Successfully created test project!")
