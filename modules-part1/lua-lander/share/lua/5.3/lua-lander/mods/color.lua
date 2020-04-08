----------------------
--------------------
-- Color Functions
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

-- __randomColor()
-- returns random color
--
-- @private
-- @return number(r, g, b)
local __randomColor = function()
    return _:round(_.__random(), _.PRECISION),
           _:round(_.__random(), _.PRECISION),
           _:round(_.__random(), _.PRECISION)
end

-- Attempt to resolve color
--   else error out
--
-- @private
-- @param string(value)
-- @return number(r, g, b)
local __resolveColor = function(value)
    _:assertNotNil('value', value)
    --
    local stat, r, g, b

    -- hex test
    stat, r, g, b = pcall(_.colorByHex, _, value)
    if stat then
        return _:round(r, _.PRECISION),
               _:round(g, _.PRECISION),
               _:round(b, _.PRECISION)
    end

    -- name test
    stat, r, g, b = pcall(_.colorByName, _, value)
    if stat then
        return _:round(r, _.PRECISION),
               _:round(g, _.PRECISION),
               _:round(b, _.PRECISION)
    end

    -- failure to find color..
    assert(false, 'Requested color `' .. value .. '` could not be resolved.')
end

-- __colorMixer([...])
-- returns set of r, g, b values based
--  off of the mean of all colors
--
-- @private
-- @param  string(...)
-- @return number(r,g,b)
local __colorMixer = function(...)
    local color  = {}
    local cnt    = 0
    local ra, ga, ba

    for __, color in pairs({...}) do
        r, g, b = __resolveColor(color)
        ra = (ra or 0) + r
        ga = (ga or 0) + g
        ba = (ba or 0) + b
        cnt = cnt + 1
    end

    return ra / cnt, ga / cnt, ba / cnt
end


------------------
-- Public Functions
--------
------
----
--

-- _:color([...])
-- spins up new color
--
-- arguments:
--  - 0  => random color
--  - 1  => color by name
--  - 2+ => mix multiple colors by name
--
-- @param  mixed(...)
-- @return number(r,g,b)
function _:color(...)
    local args = {...}

    if #args == 0 then
        -- spin up random r, g, b values
        return __randomColor()
    elseif #args == 1 then
        -- find color by name
        return __resolveColor(args[1])
    elseif #args >= 2 then
        -- mix multiple colors together
        return __colorMixer(...)
    end

    return __colorByName('black')
end

-- _:colorByName(name)
-- Returns r,g,b color values by name `value`.
--
-- @param  string(value)
-- @return number(r,g,b)
function _:colorByName(value)
    _:assertArgument('value', value, 'string')
    --
    assert(_.C[value], 'Color `' .. value .. '` does not exist.')

    return _.__unpack(_.C[value])
end

-- _:colorByHex(value)
-- Returns r,g,b color values by hex `value`.
--
-- @param  string(value)
-- @return number(r,g,b)
function _:colorByHex(value)
    _:assertArgument('value', value, 'string')
    --
    value = _.__match(value, "^#([%w]+)")

    -- if value == nil or not (value:len() == 3 or value:len() == 6) then
    --     error('Invalid hex format; acceptable formats: (i.e. #FFEEEE, #AAA)')
    -- end

    local status, r, g, b = pcall(function()
        if value:len() == 3 then
            r = _.__sub(value, 1, 1)
            g = _.__sub(value, 2, 2)
            b = _.__sub(value, 3, 3)
        else
            r = _.__sub(value, 1, 2)
            g = _.__sub(value, 3, 4)
            b = _.__sub(value, 5, 6)
        end

        return _:round(tonumber(r, 16) / 255, _.PRECISION),
               _:round(tonumber(g, 16) / 255, _.PRECISION),
               _:round(tonumber(b, 16) / 255, _.PRECISION)
    end)

    if status then
        return r, g, b
    else
        error('Invalid hex format; acceptable formats: (i.e. #FFEEEE, #AAA)')
    end
end
