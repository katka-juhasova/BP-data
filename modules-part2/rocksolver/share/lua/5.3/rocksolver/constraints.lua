-- LuaDist Package dependency constraint handling
-- Part of the LuaDist project - http://luadist.org
-- Peter Drahoš, LuaDist Project, 2010
-- Original Code borrowed from LuaRocks Project
-- License: MIT


--- Dependency handling functions.
-- Dependencies are represented in LuaDist through strings with
-- a dist name followed by a comma-separated list of constraints.
-- Each constraint consists of an operator and a version number.
-- In this string format, version numbers are represented as
-- naturally as possible, like they are used by upstream projects
-- (e.g. "2.0beta3"). Internally, LuaDist converts them to a purely
-- numeric representation, allowing comparison following some
-- "common sense" heuristics. The precise specification of the
-- comparison criteria is the source code of this module, but the
-- test/test_deps.lua file included with LuaDist provides some
-- insights on what these criteria are.

module("rocksolver.constraints", package.seeall)


local precedence = {
    scm =   -100,
    rc =    -1000,
    pre =   -10000,
    beta =  -100000,
    alpha = -1000000,
    work =  -10000000,
    devel = -100000000,
    other = -1000000000,
}


local operators = {
  ["=="]  = "==",
  ["~="]  = "~=",
  [">"]   = ">",
  ["<"]   = "<",
  [">="]  = ">=",
  ["<="]  = "<=",
  ["~>"]  = "~>",
  -- plus some convenience translations
  [""]  = "==",
  ["-"] = "==",
  ["="]   = "==",
  ["!="]  = "~="
}


local version_mt = {
    --- Equality comparison for versions.
    -- All version numbers must be equal. Missing numbers are replaced by 0.
    -- If both versions have revision numbers, they must be equal;
    -- otherwise the revision number is ignored.
    -- @param v1 table: version table to compare.
    -- @param v2 table: version table to compare.
    -- @return boolean: true if they are considered equivalent.
    __eq = function(v1, v2)
        if #v1 ~= #v2 then
            return false
        end
        for i = 1, math.max(#v1, #v2) do
            local v1i, v2i = v1[i] or {}, v2[i] or {}
            for j = 1, math.max(#v1i, #v2i) do
                local v1ij, v2ij = v1i[j] or 0, v2i[j] or 0
                if v1ij ~= v2ij then
                    return false
                end
            end
        end
        if v1.revision and v2.revision then
            return (v1.revision == v2.revision)
        end
        return true
    end,

    --- Comparison for versions.
    -- All version numbers are compared. Missing numbers are replaced by 0.
    -- If both versions have revision numbers, they are compared;
    -- otherwise the revision number is ignored.
    -- @param v1 table: version table to compare.
    -- @param v2 table: version table to compare.
    -- @return boolean: true if v1 is considered lower than v2.
    __lt = function(v1, v2)
        for i = 1, math.max(#v1, #v2) do
            local v1i, v2i = v1[i] or {}, v2[i] or {}
            for j = 1, math.max(#v1i, #v2i) do
                local v1ij, v2ij = v1i[j] or 0, v2i[j] or 0
                if v1ij ~= v2ij then
                    return (v1ij < v2ij)
                end
            end
        end
        if v1.revision and v2.revision then
            return (v1.revision < v2.revision)
        end
        return false
    end,


    -- String representation of version
    __tostring = function(v)
        return v.string
    end
}


-- Weak table for version parsing cache
local version_cache = {}
setmetatable(version_cache, {
    __mode = "kv"
})


--- Parse a version string, converting to table format.
-- A version table contains all components of the version string
-- converted to numeric format, stored in the array part of the table.
-- If the version contains a revision, it is stored numerically
-- in the 'revision' field. The original string representation of
-- the string is preserved in the 'string' field.
-- Returned version tables use a metatable
-- allowing later comparison through relational operators.
-- @param vstring string: A version number in string format.
-- @return table or nil: A version table or nil
-- if the input string contains invalid characters.
function parseVersion(vstring)
    if not vstring then return nil end
    if type(vstring) == "table" and getmetatable(vstring) == version_mt then
        return vstring
    end
    assert(type(vstring) == "string")

    -- function that actually parses the version string
    local function parse(vstring)

        local version = {}
        setmetatable(version, version_mt)
        local add_table = function()
            local t = {}
            table.insert(version, t)
            return t
        end
        local t = add_table()
        -- trim leading and trailing spaces
        vstring = vstring:match("^%s*(.*)%s*$")
        version.string = vstring
        -- store revision separately if any
        local main, revision = vstring:match("(.*)%-(%d+)$")
        if revision then
            vstring = main
            version.revision = tonumber(revision)
        end
        local number
        while #vstring > 0 do
            -- extract a number
            local token, rest = vstring:match("^(%d+)[%.%-%_]*(.*)")
            if token then
                if number == false then
                    t = add_table()
                end
                table.insert(t, tonumber(token))
                number = true
            else
                -- extract a word
                token, rest = vstring:match("^(%a+)[%.%-%_]*(.*)")
                if token then
                    if number == true then
                        t = add_table()
                    end
                    table.insert(t, precedence[token:lower()] or precedence.other)
                    number = false
                end
            end
            vstring = rest
        end
        return version
    end

    -- return the cached version, if any
    local version = version_cache[vstring]
    if version == nil then
        -- or parse the version and add it to the cache beforehand
        version = parse(vstring)
        version_cache[vstring] = version
    end

    return version
end


--- Utility function to compare version numbers given as strings.
-- @param a string: one version.
-- @param b string: another version.
-- @return boolean: True if a > b.
function compareVersions(a, b)
    return parseVersion(a) > parseVersion(b)
end


--- Consumes a constraint from a string, converting it to table format.
-- For example, a string ">= 1.0, > 2.0" is converted to a table in the
-- format {op = ">=", version={1,0}} and the rest, "> 2.0", is returned
-- back to the caller.
-- @param input string: A list of constraints in string format.
-- @return (table, string) or nil: A table representing the same
-- constraints and the string with the unused input, or nil if the
-- input string is invalid.
local function parseConstraint(input)
    assert(type(input) == "string")

    local op, version, rest = input:match("^([<>=~!]*)%s*([%w%.%_%-]+)[%s,]*(.*)")
    op = operators[op]
    version = parseVersion(version)
    if not op or not version then return nil end
    return { op = op, version = version }, rest
end


--- Convert a list of constraints from string to table format.
-- For example, a string ">= 1.0, < 2.0" is converted to a table in the format
-- {{op = ">=", version={1,0}}, {op = "<", version={2,0}}}.
-- Version tables use a metatable allowing later comparison through
-- relational operators.
-- @param input string: A list of constraints in string format.
-- @return table or nil: A table representing the same constraints,
-- or nil if the input string is invalid.
function parseConstraints(input)
    assert(type(input) == "string")

    local constraints, constraint = {}, nil
    while #input > 0 do
        constraint, input = parseConstraint(input)
        if constraint then
            table.insert(constraints, constraint)
        else
            return nil
        end
    end
    return constraints
end


--- A more lenient check for equivalence between versions.
-- This returns true if the requested components of a version
-- match and ignore the ones that were not given. For example,
-- when requesting "2", then "2", "2.1", "2.3.5-9"... all match.
-- When requesting "2.1", then "2.1", "2.1.3" match, but "2.2"
-- doesn't.
-- @param version string or table: Version to be tested; may be
-- in string format or already parsed into a table.
-- @param requested string or table: Version requested; may be
-- in string format or already parsed into a table.
-- @return boolean: True if the tested version matches the requested
-- version, false otherwise.
local function partialMatch(version, requested)
    assert(type(version) == "string" or type(version) == "table")
    assert(type(requested) == "string" or type(version) == "table")

    if type(version) ~= "table" then version = parseVersion(version) end
    if type(requested) ~= "table" then requested = parseVersion(requested) end
    if not version or not requested then return false end

    for i = 1, #requested do
        for j = 1, #requested[i] do
            if requested[i][j] ~= version[i][j] then return false end
        end
    end
    if requested.revision then
        return requested.revision == version.revision
    end
    return true
end


--- Check if a version satisfies a set of constraints.
-- @param version table: A version in table format
-- @param constraints table: An array of constraints in table format.
-- @return boolean: True if version satisfies all constraints,
-- false otherwise.
function matchConstraints(version, constraints)
    assert(type(version) == "table")
    assert(type(constraints) == "table")
    local ok = true
    setmetatable(version, version_mt)
    for _, constr in pairs(constraints) do
        local constr_version = constr.version
        setmetatable(constr.version, version_mt)
        if     constr.op == "==" then ok = version == constr_version
        elseif constr.op == "~=" then ok = version ~= constr_version
        elseif constr.op == ">"  then ok = version >  constr_version
        elseif constr.op == "<"  then ok = version <  constr_version
        elseif constr.op == ">=" then ok = version >= constr_version
        elseif constr.op == "<=" then ok = version <= constr_version
        elseif constr.op == "~>" then ok = partialMatch(version, constr_version)
        end
        if not ok then break end
    end
    return ok
end


--- Check if a version string is satisfied by a constraint string.
-- @param version string: A version in string format
-- @param constraints string: Constraints in string format.
-- @return boolean: True if version satisfies all constraints,
-- false otherwise.
function constraint_satisified(version, constraints)
    local const = parseConstraints(constraints)
    local ver = parseVersion(version)
    if const and ver then
        return matchConstraints(ver, const)
    end
    return nil, "Error parsing versions."
end


--- Split dist name into name and constraints.
-- @param name string: A string containing name and version constraints eg. "lua-5.1.4" or "luajit >= 1.0 < 2.0"
-- @return string, string: Returns separated name and constraints
function split(name)
    assert(type(name) == "string")

    local cut = string.find(name, "[%s=<>~]+")

    -- Cut the string and remove - from version if needed.
    if cut then
        return string.sub(name, 0, cut-1), string.gsub(string.sub(name, cut), "^[-%s]*", "")
    end
    return name, nil
end
