local CMakeBuilder = require 'rockspec2cmake.CMakeBuilder'
local pl = require "pl.import_into"()

local rockspec2cmake = {}

-- Converts lua table into string useable for initialization of CMake list.
-- Encloses each value of table in double quotes ("), escapes double quotes
-- in values and concatenates them using single space.
-- If argument is nil, returns empty string.
-- If arguments is string itself, processes it as one element table.
-- If value in table is in form of rockspec variable $(var) or $var,
-- converts it to cmake variable ${var}.
local function table_to_cmake_list(tbl)
    local function try_convert_var(str)
        if str:match("^%$%(.*%)$") then
            return str:gsub("%(", "{"):gsub("%)", "}")
        elseif str:match("^%$.*$") then
            return str:gsub("^%$", "${") .. "}"
        end

        return str
    end

    local function quote_escape(str)
        return "\"" .. str:gsub("\"", "\\\"") .. "\""
    end

    if type(tbl) == "string" then
        tbl = {tbl}
    end

    res = ""
    for _, v in pairs(tbl or {}) do
        if res == "" then
            res = quote_escape(try_convert_var(v))
        else
            res = res .. " " .. quote_escape(try_convert_var(v))
        end
    end

    return res
end

local function is_string_array(tbl)
    for k, v in pairs(tbl) do
        if type(k) ~= "number" or type(v) ~= "string" then
            return nil
        end
    end

    return true
end

local process_builtin

local function process_install(cmake, install, platform)
    for what, files in pairs(install) do
        for key, src in pl.tablex.sort(files) do
            local dst, name

            if type(key) == "string" then
                -- Assume that key is in lua module format
                if what == "lua" then
                    dst = pl.path.dirname(key:gsub("%.", "/"))
                    name = pl.path.basename(key:gsub("%.", "/")) .. ".lua"
                else
                    dst = pl.path.dirname(key)
                    name = pl.path.basename(key)
                end
            else
                dst = ""
                name = pl.path.basename(src)
            end


            cmake:set_cmake_variable("BUILD_INSTALL_" .. what .. "_" .. key .. "_SRC", src, platform)
            cmake:set_cmake_variable("BUILD_INSTALL_" .. what .. "_" .. key .. "_DST", dst, platform)
            cmake:set_cmake_variable("BUILD_INSTALL_" .. what .. "_" .. key .. "_RENAME", name, platform)
            cmake:set_cmake_variable("BUILD_INSTALL_" .. what, key, platform, true)
        end
    end
end

local function process_module(cmake, name, info, platform)
    -- Pathname of Lua file or C source, for modules based on single source file
    if type(info) == "string" then
        local ext = info:match(".([^.]+)$")
        if ext == "lua" then
            cmake:add_lua_module(name, platform)
        else
            cmake:add_cxx_target(name, platform)
        end

        cmake:set_cmake_variable(name .. "_SOURCES", info, platform)
    -- Two options:
    -- array of strings - pathnames of C sources
    -- table - possible fields sources, libraries, defines, incdirs, libdirs
    elseif type(info) == "table" then
        cmake:add_cxx_target(name, platform)

        if is_string_array(info) then
            cmake:set_cmake_variable(name .. "_SOURCES", table_to_cmake_list(info), platform)
        else
            cmake:set_cmake_variable(name .. "_SOURCES", table_to_cmake_list(info.sources), platform)
            cmake:set_cmake_variable(name .. "_LIB_NAMES", table_to_cmake_list(info.libraries), platform)
            cmake:set_cmake_variable(name .. "_DEFINES", table_to_cmake_list(info.defines), platform)
            cmake:set_cmake_variable(name .. "_INCDIRS", table_to_cmake_list(info.incdirs), platform)
            cmake:set_cmake_variable(name .. "_LIBDIRS", table_to_cmake_list(info.libdirs), platform)
        end
    end
end

local function process_modules(cmake, modules, platform)
    for name, info in pairs(modules) do
        process_module(cmake, name, info, platform)
    end
end

local function process_platform_overrides(cmake, platforms)
    for platform, build in pairs(platforms) do
        process_builtin(cmake, build, platform)
    end
end

process_builtin = function(cmake, build, platform)
    for key, value in pairs(build) do
        if key == "install" then
            process_install(cmake, value, platform)
        elseif key == "copy_directories" then
            cmake:set_cmake_variable("BUILD_COPY_DIRECTORIES", table_to_cmake_list(value), platform)
        elseif key == "modules" then
            process_modules(cmake, value, platform)
        elseif key == "platforms" then
            assert(platform == nil)
            process_platform_overrides(cmake, value)
        end
    end
end

local function process_ext_dep(cmake, ext_dep, platform)
    for key, value in pairs(ext_dep) do
        if key == "platforms" then
            assert(platform == nil)
            for platform, ext_dep2 in pairs(value) do
                process_ext_dep(cmake, ext_dep2, platform)
            end
        else
            cmake:add_ext_dep(key, platform)
        end
    end
end

-- Lua interface for rockspec2cmake utility
-- Generates cmake commands from given 'rockspec' table and returns them
-- as string, or returns nil, error_message on error.
-- If argument 'output_dir' is provided, this function creates file CMakeLists.txt
-- in provided directory
function rockspec2cmake.process_rockspec(rockspec, output_dir)
    assert(type(rockspec) == "table", "rockspec2cmake.process_rockspec: Argument 'rockspec' is not a table.")
    assert(output_dir == nil or (type(output_dir) == "string" and pl.path.isabs(output_dir)), "rockspec2cmake.process_rockspec: Argument 'output_dir' not an absolute path.")

    local cmake = CMakeBuilder.new(rockspec.package, rockspec.version)

    -- Parse (un)supported platforms
    if rockspec.supported_platforms ~= nil then
        local supported_platforms_check_str = ""
        for _, plat in pairs(rockspec.supported_platforms) do
            local neg, plat = plat:match("^(!?)(.*)")
            if neg == "!" then
                cmake:add_unsupported_platform(plat)
            else
                cmake:add_supported_platform(plat)
            end
        end
    end

    -- Parse external dependencies
    if rockspec.external_dependencies ~= nil then
        process_ext_dep(cmake, rockspec.external_dependencies)
    end

    local cmake_commands = nil

    -- Parse build rules
    if rockspec.build == nil then
        return nil, "Rockspec does not contain build information"
    -- "none" build type can still contain "install" or "copy_directories" fields
    elseif rockspec.build.type == "builtin" or rockspec.build.type == "none" then
        process_builtin(cmake, rockspec.build)
        cmake_commands = cmake:generate()
    -- Use existing cmake
    elseif rockspec.build.type == "cmake" then
        if rockspec.build.cmake then
            cmake_commands = rockspec.build.cmake
        else
            return nil, "Rockspec build type is cmake, please use the attached CMakeLists.txt"
        end
    else
        return nil, "Unhandled rockspec build type: " .. rockspec.build.type
    end

    if output_dir ~= nil then
        local output_file = io.open(pl.path.join(output_dir, "CMakeLists.txt"), "w")
        if not output_file then
            return nil, "Error creating CMakeLists.txt file in '" .. output_dir .. "'"
        end

        output_file:write(cmake_commands)
        output_file:close()
    end

    return cmake_commands
end

return rockspec2cmake
