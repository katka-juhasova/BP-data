----------------------
--------------------
-- Assert Functions
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


------------------
-- Public Functions
--------
------
----
--

-- _:assertArgument(name, var, expect, [default])
-- Assert `var` is am `expect`ed data type, and
--  assigns `default` if `var` = nil.
--
-- @param  string(name)    - identifier
-- @param  mixed(var)      - argument variable
-- @param  string(expect)  - expected data type
-- @param  mixed(default)  - default value (only if `var` == nil)
-- @return mixed(var)
function _:assertArgument(name, var, expect, default)
    local expected   = _.__gsub(_.__lower(expect), "^%a", string.upper)
    local expectTest = _['is' .. expected]
    --
    assert(_.__type(name) == 'string', 'assertArgument :: `name` should be a `string`!')
    assert(_.__type(expect) == 'string', 'assertArgument :: `expect` should be a `string`!')
    assert(_.__type(expectTest) == 'function', 'assertArgument :: invalid `expect` option!')
    --
    -- set default value, if requested..
    if default then
        var = var ~= nil and var or default
    end

    -- assert data type is as expected..
    assert(expectTest(_, var), 'Argument `' .. name .. '` is a `' .. _.__type(var) .. '` but should be a `' .. expect .. '`.')
    return var
end

-- _:assertEqualSize(name, [...])
-- Assert if not all `...` values are the same length.
--
-- @param  string(name) - identifier
-- @param  mixed(...)   - values to assert
-- @return mixed(...)
function _:assertEqualSize(name, ...)
    assert(_.__type(name) == 'string', 'assertArgument :: `name` should be a `string`!')
    ---
    local values = {...}

    if #values > 0 then
        local expectedSize = _:size(values[1])

        for k, v in pairs(values) do
            assert(expectedSize == _:size(v), 'Argument(s) `' .. name .. '` must all be of equal size.')
        end
    end

    return ...
end

-- _:assertIsBoolean(name, var)
-- Asserts `var` is of boolean data type.
--
-- @param  string(name) - identifier
-- @param  mixed(var)   - variable to assert
-- @return mixed(var)
function _:assertIsBoolean(name, var)
    assert(_.__type(name) == 'string', 'assertArgument :: `name` should be a `string`!')
    assert(var ~= nil, 'assertArgument :: `var` must have a non-nil value!')
    ---
    assert(_:isBoolean(var), 'Argument `' .. name .. '` is a `' .. _.__type(var) .. '` but should be a `boolean`.')
end

-- _:assertIsNumber(name, var)
-- Assert if `var` is not a `number` data type.
--
-- @param  string(name) - identifier
-- @param  mixed(var)  - value to assert
-- @return mixed(var)
function _:assertIsNumber(name, var)
    assert(_.__type(name) == 'string', 'assertArgument :: `name` should be a `string`!')
    assert(var ~= nil, 'assertArgument :: `var` must have a non-nil value!')
    ---
    assert(_:isNumber(var), 'Argument `' .. name .. '` is a `' .. _.__type(var) .. '` but should be a `number`.')
    return var
end

-- _:assertIsRegex(name, var)
-- Alias of [_:assertIsRegexPattern](#assertIsRegexPattern).
--
-- @param string(name) - identifier
-- @param mixed(var)   - variable to assert
-- @return mixed(var)
function _:assertIsRegex(name, var)
    return _:assertIsRegexPattern(name, var)
end

-- _:assertIsRegexPattern(name, var)
-- Assert if `var` is not a regular expression pattern.
--
-- @param string(name) - identifier
-- @param mixed(var)   - variable to assert
-- @return mixed(var)
function _:assertIsRegexPattern(name, var)
    assert(_.__type(name) == 'string', 'assertArgument :: `name` should be a `string`!')
    ---
    assert(_:isRegexPattern(var), 'Argument `' .. name .. '` must be a valid regex pattern.')
    return var
end

-- _:assertIsString(name, var)
-- Assert if `var` is not a `string` data type.
--
-- @param  string(name) - identifier
-- @param  mixed(var)   - variable to assert
-- @return mixed(var)
function _:assertIsString(name, var)
    assert(_.__type(name) == 'string', 'assertArgument :: `name` should be a `string`!')
    assert(var ~= nil, 'assertArgument :: `var` must have a non-nil value!')
    ---
    assert(_:isString(var), 'Argument `' .. name .. '` is a `' .. _.__type(var) .. '` but should be a `string`.')
    return var
end

-- _:assertIsTable(name, var)
-- Assert if `var` is not a `table` data type.
--
-- @param  string(name) - identifier
-- @param  mixed(var)   - variable to assert
-- @return mixed(var)
function _:assertIsTable(name, var)
    assert(_.__type(name) == 'string', 'assertArgument :: `name` should be a `string`!')
    assert(var ~= nil, 'assertArgument :: `var` must have a non-nil value!')
    ---
    assert(_:isTable(var), 'Argument `' .. name .. '` is a `' .. _.__type(var) .. '` but should be a `table`.')
    return var
end

-- _:assertMinSize(name, var, expect)
-- Assert if `var` is < `expect` size.
--
-- @param  string(name)   - identifier
-- @param  mixed(var)     - variable to assert
-- @param  number(expect) - max size expected
-- @return mixed(var)
function _:assertMinSize(name, var, expect)
    assert(_.__type(name) == 'string', 'assertArgument :: `name` should be a `string`!')
    assert(var ~= nil, 'assertArgument :: `var` must have a non-nil value!')
    assert(_.__type(expect) == 'number', 'assertArgument :: `expect` should be a `number`!')
    ---
    assert(_:size(var) >= expect, 'Argument `' .. name .. '` must be greater than or equal to ' .. expect .. ' in size.')
    return var
end

-- _:assertMaxSize(name, var, expect)
-- Assert if `var` is > `expect` size.
--
-- @param  string(name)   - identifier
-- @param  mixed(var)     - variable to assert
-- @param  number(expect) - min size expected
-- @return mixed(var)
function _:assertMaxSize(name, var, expect)
    assert(_.__type(name) == 'string', 'assertArgument :: `name` should be a `string`!')
    assert(var ~= nil, 'assertArgument :: `var` must have a non-nil value!')
    assert(_.__type(expect) == 'number', 'assertArgument :: `expect` should be a `number`!')
    ---
    assert(_:size(var) <= expect, 'Argument `' .. name .. '` must be less than or equal to ' .. expect .. ' in size.')
    return var
end

-- _:assertIsNotNil(name, var)
-- Assert if `var` is nil.
--
-- @param  string(name) - identifier
-- @param  mixed(var)   - variable to assert
-- @return mixed(var)
function _:assertNotNil(name, var)
    assert(_.__type(name) == 'string', 'assertArgument :: `name` should be a `string`!')
    ---
    assert(var ~= nil, 'Argument `' .. name .. '` must have a non-nil value.')
    return var
end

-- _:assertIsNotZero(name, var)
-- Assert if `var` is 0.
--
-- @param  string(name) - identifier
-- @param  mixed(var)   - variable to assert
-- @return mixed(var)
function _:assertNotZero(name, var)
    assert(_.__type(name) == 'string', 'assertArgument :: `name` should be a `string`!')
    ---
    assert(var ~= 0, 'Argument `' .. name .. '` should not be 0.')
    return var
end
