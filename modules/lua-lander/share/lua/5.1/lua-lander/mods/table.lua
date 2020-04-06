----------------------
--------------------
-- Table Functions
----------------
--------------
------------
----------
--------
------
----
--


------------------
-- Private Functions
--------
------
----
--

-- Insert element property into `t`
--  based on index type.
--
-- @private
-- Note: assumes `t` is a table.
local __insert = function(t, k, v)
    if _:isNumber(k) then
        _.__insert(t, v)
    else
        t[k] = v
    end

    return t
end

local __remove = function(t, k, v)
    if _:isNumber(k) then
        _.__remove(t, k, v)
    else
        t[k] = nil
    end

    return t
end

-- Returns table of keys from `t` in
--  natural order
--
-- Credit: [lua-users](http://lua-users.org/wiki/SortedIteration)
local __orderedKeys = function(t)
    local keys = {}
    _:i('len', 0)

    for k, v in pairs(t) do
        keys[_:up('len')] = k
    end

    -- sort, multi-type
    _.__sort(keys, function(a, b)
        local at = _.__type(a)
        local bt = _.__type(b)
        if      at ~= bt       then return at < bt
        elseif _:isString(at) or
               _:isNumber(at)  then return a < b
        elseif _:isBoolean(at) then return at == true
        else                        return tostring(a) < tostring(b)
        end
    end)

    return keys
end

-- Imitates next(t, state).
-- Returns next key/value pair in
--  natural order.
--
-- Credit: [lua-users](http://lua-users.org/wiki/SortedIteration)
local __next = function(t, state)
    local key = nil

    if state == nil then
        t.__orderedIndex = __orderedKeys(t)
        key = t.__orderedIndex[1]
    else
        for i = 1, #t.__orderedIndex do
            if t.__orderedIndex[i] == state then
                key = t.__orderedIndex[i + 1]
            end
        end
    end

    -- return next key/value pair..
    if key then
        return key, t[key]
    end

    -- done.
    t.__orderedIndex = nil
    return
end

-- Imitates pairs(t).
-- Iterates over `t` in natural order.
local __iterator = function(t)
    return __next, t, nil
end


------------------
-- Public Functions
--------
------
----
--

-- _:chunk(tabl, [size=1])
-- Splits elements of `tabl` into groups of `size`.
--
-- @param  table(tabl)       - table to process
-- @param  number([size=1])  - length of each chunk
-- @return table
function _:chunk(tabl, size)
    tabl = _:assertArgument('tabl', tabl, 'table')
    size = _:assertArgument('size', size, 'number', 1)
    --
    local out, sub = {}, {}
    local max = _:size(tabl)
    local cnt = 0

    for k, v in __iterator(tabl) do
        sub = __insert(sub, k, v)
        cnt = cnt + 1

        if cnt % size == 0 or cnt == max then
            _.__insert(out, sub)
            sub = {}  -- reset
        end
    end

    return out
end

-- _:combine(keys, values)
-- creates new `tabl` with `keys` as the
--  keys and `values` as the values.
--
-- requirement:
--   both tables must be equal in size
--
-- @param  table(keys)    - keys table
-- @param  table(values)  - values table
-- @return table
function _:combine(keys, values)
    keys   = _:assertArgument('keys', keys, 'table')
    values = _:assertArgument('values', values, 'table')
    _:assertEqualSize('tabl', keys, values)
    --
    local out = {}
    local k2, v2

    for k1, v1 in __iterator(keys) do
        k2, v2 = __next(values, k2)

        __insert(out, v1, v2)
    end

    return out
end

-- _:compact(tabl)
-- Creates copy of `tabl` with Lua-falsy
--  values filtered out.
--
-- @param  table(tabl)
-- @return table
function _:compact(tabl)
    tabl = _:assertArgument('tabl', tabl, 'table')
    --
    return _:filter(tabl, 'isTruthy')
end

-- _:conformsTo(value, source)
-- Determines if `value` conforms to `source`,
--  by invoking the predicate properties of source
--  with corresponding propery values of `value`.
--
-- @param  table(value)
-- @param  table(source)
-- @return boolean
function _:conformsTo(tabl, source)
    tabl   = _:assertArgument('tabl', tabl, 'table')
    source = _:assertArgument('source', source, 'table')
    --
    for k, v in pairs(tabl) do
        if _:isFunction(source[k]) then
            local stat, conform = _:attempt(source[k], v, k)

            if stat and conform == false then
                return false
            end
        end
    end

    return true
end

-- _:difference(tabl, other)
-- Creates copy of `tabl`, excluding any same
--  values from `other`.
--
-- @param  table(tabl)   - table to process
-- @param  table(other)  - compare table
-- @return table
function _:difference(tabl, other)
    tabl  = _:assertArgument('tabl', tabl, 'table')
    other = _:assertArgument('other', other, 'table')
    --
    --
    local out    = _:copy(tabl)
    local keys   = {}
    local values = {}
    -- create reference table...
    for k, v in pairs(other) do
        keys[k]   = true
        values[v] = true
    end
    -- ...now exclude
    for k, v in pairs(out) do
        if keys[k] and values[v] then
            out[k] = nil
        end
    end
    --
    return out
end

-- _:flatten(tabl)
-- Creates new `tabl` flattened one level deep.
--
-- @param  table(tabl)   - table to flatten
-- @return table
function _:flatten(tabl)
    tabl = _:assertArgument('tabl', tabl, 'table')
    --
    local out = {}

    for k1, v1 in __iterator(tabl) do
        if _:isTable(v1) then
            for k2, v2 in __iterator(v1) do
                __insert(out, k2, v2)
            end
        else
            __insert(out, k1, v1)
        end
    end

    return out
end

-- _:flattenDeep(tabl)
-- Creates new `tabl`, recursively flattening table.
--
-- @param  table(tabl)   - table to flatten
-- @return table
function _:flattenDeep(tabl)
    tabl = _:assertArgument('tabl', tabl, 'table')
    --
    local function flatten(out, values)
        for k, v in __iterator(values) do
            if _:isTable(v) then
                flatten(out, v)
            else
                __insert(out, k, v)
            end
        end

        return out
    end

    return flatten({}, tabl)
end

-- _:filter(tabl, iteratee)
-- Creates copy of `tabl` with values that fail
--  `iteratee` filtered out.
--
-- Note:
-- `iteratee` will receive arguments:
--  * `value`
--  * `key`

-- Warning:
-- Lua tables are volitile when it comes to
--  manipulating keys manually.
--
-- @param  table(tabl)
-- @param  function(iteratee)
-- @return table
function _:filter(tabl, iteratee)
    tabl     = _:assertArgument('tabl', tabl, 'table')
    iteratee = _:assertArgument('tabl', iteratee, 'function')
    --
    local out = {}

    for k, v in __iterator(tabl) do
        local stat, passed = _:attempt(iteratee, v, k)

        if stat and passed == true then
            __insert(out, k, v)
        end
    end

    return out
end

-- _:find(tabl, predicate)
-- Return first element in `tabl`, which
--  `predicate` returns a truthy value.
--
-- @param  table(tabl)         - table to fill
-- @param  function(predicate) - function ivoked per element
-- @return mixed(v), mixed(k)
function _:find(tabl, predicate)
    tabl      = _:assertArgument('tabl', tabl, 'table')
    predicate = _:assertArgument('predicate', predicate, 'function')
    --
    for k, v in __iterator(tabl) do
        local stat, res = _:attempt(predicate, v, k)

        if stat and _:isTruthy(res) then
            return v, k
        end
    end
end

-- _:keys(tabl)
-- Creates new table made up of keys from `tabl`.
--
-- @param  table(tabl)
-- @return table
function _:keys(tabl)
    tabl = _:assertArgument('tabl', tabl, 'table')
    --
    return __orderedKeys(tabl)
end

-- _:map(tabl, iteratee)
-- Creates new table executing `iteratee`
--  on every element of `tabl`.
--
-- @param  table(keys)        - keys table
-- @param  function(iteratee) - values table
-- @return table
function _:map(tabl, iteratee)
    tabl     = _:assertArgument('tabl', tabl, 'table')
    iteratee = _:assertArgument('iteratee', iteratee, 'function')
    --
    local out = {}

    for k, v in __iterator(tabl) do
        __insert(out, k, _:force(iteratee, v, k))
    end

    return out
end

-- _:merge(...)
-- Creates new table merging from left to right.
--
-- Warning:
--  Overwritting may occur.
--
-- @param  table(keys)        - keys table
-- @param  function(iteratee) - values table
-- @return table
function _:merge(...)
    local out = {}

    for _k, tabl in ipairs({...}) do
        if _:isTable(tabl) then
            for k, v in __iterator(tabl) do
                __insert(out, k, v)
            end
        end
    end

    return out
end

-- _:resize(tabl, size)
-- Creates copy of `tabl`, resized to `size`.
--
-- @param  table(tabl)
-- @param  number(size)
-- @return table
function _:resize(tabl, size)
    tabl = _:assertArgument('tabl', tabl, 'table')
    size = _:assertArgument('size', size, 'number')
    --
    local currSize = _:size(tabl)
    local newSize  = currSize - _:abs(size)

    newSize = _.__max(0, newSize)

    if _:isNegative(size) then
        newSize = newSize * -1
    end

    return _:drop(tabl, newSize)
end

-- _:unique(tabl)
-- Creates unique set of elements, dropping duplicate indices.
--
-- @param  table(tabl)
-- @return table
function _:unique(tabl)
    tabl = _:assertArgument('tabl', tabl, 'table')
    --
    local out    = {}
    local values = {}

    for k, v in __iterator(tabl) do
        if not values[v] then
            out[k] = v
            values[v] = true
        end
    end

    return out
end

-- _:values(tabl)
-- Creates new table made up of values from `tabl`.
--
-- @param  table(tabl)
-- @return table
function _:values(tabl)
    tabl = _:assertArgument('tabl', tabl, 'table')
    --
    local out = {}
    _:i('i', 0)

    for k, v in __iterator(tabl) do
        __insert(out, _:up('i'), v)
    end

    return out
end
