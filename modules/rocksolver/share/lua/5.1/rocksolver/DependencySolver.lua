-- LuaDist Package dependency solver
-- Part of the LuaDist project - http://luadist.org
-- Author: Martin Srank, hello@smasty.net
-- License: MIT

local const = require("rocksolver.constraints")
local utils = require("rocksolver.utils")
local Package = require("rocksolver.Package")


local DependencySolver = {}
DependencySolver.__index = DependencySolver
setmetatable(DependencySolver, {
__call = function(_, manifest, platform)
    local self = setmetatable({}, DependencySolver)

    self.manifest = manifest
    self.platform = platform

    return self
end
})


-- Check if a given package is in the provided list of installed packages.
-- Can also check for package version constraint.
function DependencySolver:is_installed(pkg_name, installed, pkg_constraint)
    assert(type(pkg_name) == "string", "DependencySolver.is_installed: Argument 'pkg_name' is not a string.")
    assert(type(installed) == "table", "DependencySolver.is_installed: Argument 'installed' is not a table.")
    assert(not pkg_constraint or type(pkg_constraint) == "string", "DependencySolver.is_installed: Argument 'pkg_constraint' is not a string.")

    local function selected(pkg)
        return pkg.selected and "selected" or "installed"
    end
    local constraint_str = pkg_constraint and " " .. pkg_constraint or ""

    local pkg_installed, err = false, nil

    for _, installed_pkg in pairs(installed) do
        assert(getmetatable(installed_pkg) == Package, "DependencySolver.is_installed: Argument 'installed' does not contain Package instances.")
        if pkg_name == installed_pkg.name then
            if not pkg_constraint or installed_pkg:matches(pkg_name .. " " .. pkg_constraint) then
                pkg_installed = true
                break
            else
                err = ("Package %s%s needed, but %s at version %s.")
                    :format(tostring(pkg_name), constraint_str, selected(installed_pkg), installed_pkg.version)
                break
            end
        end
    end

    return pkg_installed, err
end


function DependencySolver:find_candidates(package)
    assert(type(package) == "string", "DependencySolver.find_candidates: Argument 'package' is not a string.")

    pkg_name, pkg_constraint = const.split(package)
    pkg_constraint = pkg_constraint or ""
    if not self.manifest.packages[pkg_name] then return {} end

    local found = {}
    for version, spec in utils.sort(self.manifest.packages[pkg_name], const.compareVersions) do
        local pkg = Package(pkg_name, version, spec)
        if pkg:matches(package) and pkg:supports_platform(self.platform) then
            table.insert(found, pkg)
        end
    end

    return found
end


-- Returns list of all needed packages to install the "package" using the manifest and a list of already installed packages.
function DependencySolver:resolve_dependencies(package, installed, dependency_parents, tmp_installed)
    installed = installed or {}
    dependency_parents = dependency_parents or {}
    tmp_installed = tmp_installed or utils.deepcopy(installed)

    if getmetatable(package) == Package then
        package = tostring(package)
    end
    assert(type(package) == "string", "DependencySolver.resolve_dependencies: Argument 'package' is not a string.")
    assert(type(installed) == "table", "DependencySolver.resolve_dependencies: Argument 'installed' is not a table.")
    assert(type(dependency_parents) == "table", "DependencySolver.resolve_dependencies: Argument 'dependency_parents' is not a table.")
    assert(type(tmp_installed) == "table", "DependencySolver.resolve_dependencies: Argument 'tmp_installed' is not a table.")


    -- Sanitize and extract package name and constraint
    package = package:gsub("%s+", " "):lower()
    local pkg_name, pkg_const = const.split(package)

    --[[ for future debugging:
    print('resolving: '.. package)
    print('    installed: ', utils.table_tostring(installed))
    print('    tmp_installed: ', utils.table_tostring(tmp_installed))
    print('- is installed: ', self:is_installed(pkg_name, tmp_installed, pkg_const))
    --]]

    -- Check if the package is already installed
    local pkg_installed, err = self:is_installed(pkg_name, tmp_installed, pkg_const)

    if pkg_installed then return {} end
    if err then return nil, err end

    local to_install = {}

    -- Get package candidates
    local candidates = self:find_candidates(package)
    if #candidates == 0 then
        return nil, "No suitable candidate for package \"" .. package .. "\" found."
    end

    -- For each candidate (highest version first)
    for _, pkg in ipairs(candidates) do

        --[[ for future debugging:
        print('  candidate: '.. pkg)
        print('      installed: ', utils.table_tostring(installed))
        print('      tmp_installed: ', utils.table_tostring(tmp_installed))
        print('      to_install: ', utils.table_tostring(to_install))
        print('      dependencies: ', utils.table_tostring(pkg:dependencies(self.platform)))
        print('  -is installed: ', self:is_installed(pkg.name, tmp_installed, pkg_const))
        -- ]]

        -- Clear state from previous iteration
        pkg_installed, err = false, nil

        -- Check if it was already added by previous candidate
        pkg_installed, err = self:is_installed(pkg.name, tmp_installed, pkg_const)
        if pkg_installed then
            break
        end

        -- Maybe check for conflicting packages here if we will support that functionallity

        -- Resolve dependencies of the package
        local deps = pkg:dependencies(self.platform)
        if deps then

            -- For preventing circular dependencies
            table.insert(dependency_parents, pkg.name)

            -- For each dep of pkg
            for _, dep in ipairs(deps) do
                -- Detect circular dependencies
                local has_circular_dependency = false
                local dep_name = const.split(dep)
                for _, parent in ipairs(dependency_parents) do
                    if dep_name == parent then
                        has_circular_dependency = true
                        break
                    end
                end

                -- If circular deps detected
                if has_circular_dependency then
                    err = "Error getting dependency of \"" .. pkg .. "\": \"" .. dep .. "\" is a circular dependency."
                    break
                end

                -- No circular deps - recursively call on this dependency package.
                local deps_to_install, deps_err = self:resolve_dependencies(dep, installed, dependency_parents, tmp_installed)

                if deps_err then
                    err = "Error getting dependency of \"" .. pkg .. "\": " .. deps_err
                    break
                end

                -- If suitable deps found - add them to the to_install list.
                if deps_to_install then
                    for _, dep_to_install in ipairs(deps_to_install) do
                        table.insert(to_install, dep_to_install)
                        table.insert(tmp_installed, dep_to_install)
                        table.insert(installed, dep_to_install)
                    end
                end
            end

            -- Remove last pkg from the circular deps stack
            table.remove(dependency_parents)
        end

        if not err then
            -- Mark package as selected and add it to tmp_installed
            pkg.selected = true
            table.insert(tmp_installed, pkg)
            table.insert(to_install, pkg)
            --print("+ Installing package " .. pkg)
        else
            -- If some error occured, reset to original state
            to_install = {}
            tmp_installed = utils.deepcopy(installed)
        end
    end


    -- If package is not installed and no candidates were suitable, return last error.
    if #to_install == 0 and not pkg_installed then
        return nil, err
    end


    return to_install, nil
end


return DependencySolver
