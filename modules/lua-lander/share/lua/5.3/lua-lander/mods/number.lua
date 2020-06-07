----------------------
--------------------
-- Number Functions
----------------
--------------
------------
----------
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

-- _:clamp(num, min, max)
-- Performs clamp on `num` so it fits
--  between `min` and `max` values.
--
-- @param  number(num)
-- @param  number(min)
-- @param  number(max)
-- @return number
function _:clamp(num, min, max)
    num   = _:assertArgument('num', num, 'number')
    min   = _:assertArgument('min', min, 'number')
    max   = _:assertArgument('max', max, 'number')
    --
    local trueMin = _:min(min, max)
    local trueMax = _:max(min, max)

    return _:max(trueMin, _:min(num, trueMax))
end

-- _:down(name, [n=1])
-- A shortcut for decrementing a numeric value.
--
-- @param  string(name)
-- @param  number(n)
-- @return number
function _:down(name, n)
    name = _:assertArgument('name', name, 'string')
    n    = _:assertArgument('n', n, 'number', 1)
    --
    if _:isNil(_.I[name]) then
        error('Cannot find Incrementor with name `' .. name .. '`. Did you call `_:i(\'' .. name .. '\') ?`')
    end

    -- decrement
    _.I[name] = _.I[name] - n

    return _.I[name]
end

-- _:i(name, [value=0])
-- Creates new incrementor variable.
--
-- note:
--  can be used with _:down, _:up
--
-- @param  string(name)
-- @param  number(value)
-- @return number
function _:i(name, value)
    name = _:assertArgument('name', name, 'string')
    --
    if _:isNumber(value) then
        _.I[name] = value
    end

    return _.I[name]
end

-- _:lerp(num, min, max)
-- Performs linear interpolation on a `number`
--  between `min` and `max` values.
--
-- @param  number(num)
-- @param  number(min)
-- @param  number(max)
-- @return number
function _:lerp(num, min, max)
    num   = _:assertArgument('num', num, 'number')
    min   = _:assertArgument('min', min, 'number')
    max   = _:assertArgument('max', max, 'number')
    --
    local trueMin = _:min(min, max)
    local trueMax = _:max(min, max)

    return (max - min) * num + min
end

-- _:mapTo(num, minSource, maxSource, minDest, maxDest)
-- Maps `num` from source range (`minSource/maxSource`)
--  to destination range (`minDest/maxDest`).
--
-- @param  number(num)
-- @param  number(minSource)
-- @param  number(maxSource)
-- @param  number(minDest)
-- @param  number(maxDest)
-- @return number
function _:mapTo(num, minSource, maxSource, minDest, maxDest)
    num        = _:assertArgument('num', num, 'number')
    minSource  = _:assertArgument('minSource', minSource, 'number')
    maxSource  = _:assertArgument('maxSource', maxSource, 'number')
    minDest    = _:assertArgument('minDest', minDest, 'number')
    maxDest    = _:assertArgument('maxDest', maxDest, 'number')
    --
    local trueSourceMin = _:min(minSource, maxSource)
    local trueSourceMax = _:max(minSource, maxSource)
    local trueDestMin   = _:min(minDest, maxDest)
    local trueDestMax   = _:max(minDest, maxDest)
    local norm          = _:norm(num, trueSourceMin, trueSourceMax)

    return _:lerp(norm, trueDestMin, trueDestMax)
end

-- _:norm(num, [min=0], [max=1])
-- Computes normalized `num` between `min/max` range.
--
-- @param  number(num)
-- @param  number(min)
-- @param  number(max)
-- @return number
function _:norm(num, min, max)
    num   = _:assertArgument('num', num, 'number')
    min   = _:assertArgument('min', min, 'number', 0)
    max   = _:assertArgument('max', max, 'number', 1)
    --
    return (num - min) / (max - min)
end

-- _:up(name, [n=1])
-- A shortcut for incrementing a numeric value.
--
-- @param  string(name)
-- @param  number(n)
-- @return number
function _:up(name, n)
    name = _:assertArgument('name', name, 'string')
    n    = _:assertArgument('n', n, 'number', 1)
    --
    if _:isNil(_.I[name]) then
        error('Cannot find Incrementor with name `' .. name .. '`. Did you call `_:i(\'' .. name .. '\') ?`')
    end

    -- increment
    _.I[name] = _.I[name] + n

    return _.I[name]
end
