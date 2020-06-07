----------------------
--------------------
-- Math Functions
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

-- _:abs(num)
-- Returns absolute value of `num`.
--
-- @param  number(num)
-- @return number
function _:abs(num)
    num = _:assertArgument('num', num, 'number')
    --
    return _.__abs(num)
end

-- _:add(...)
-- Adds all `...` numbers and returns sum.
--
-- @param  number(...)
-- @return number
function _:add(...)
    return _:sum(...)
end

-- _:bin2Dec(bin)
-- Converts `bin` representation into
--  it's base-10 numeric counterpart.
--
-- @param  string(bin)
-- @return number
function _:bin2Dec(bin)
    bin = _:assertArgument('bin', bin, 'string')
    --
    local dec = 0
    local exp = _.__len(bin) - 1

    for v in _.__gmatch(bin, '.') do
        dec = dec + tonumber(v) * 2 ^ exp
        exp = exp - 1
    end

    return dec
end

-- _:bin2Hex(bin)
-- Converts `bin` representation into
--  it's hexadecimal string counterpart.
--
-- @param  string(bin)
-- @return string
function _:bin2Hex(bin)
    bin = _:assertArgument('bin', bin, 'string')
    --
    return _:dec2Hex(_:bin2Dec(bin))
end

-- _:bitwiseAND(x, y)
-- Perform bitwise AND operation on `x` and
--  returns the result.
--
-- @param  number(x)
-- @param  number(y)
-- @return number
function _:bitwiseAND(x, y)
    x = _:assertArgument('x', x, 'number')
    y = _:assertArgument('y', y, 'number')
    --
    local bx  = _:padStart(_:dec2Bin(x), 32, '0')
    local by  = _:padStart(_:dec2Bin(y), 32, '0')
    local cx  = _:words(bx, '.')
    local cy  = _:words(by, '.')
    local out = ''

    for i = 1, #cx do
        if cx[i] == cy[i] then
            out = out .. cx[i]
        else
            out = out .. '0'
        end
    end

    return _:bin2Dec(out)
end

-- _:bitwiseNOT(x)
-- Perform bitwise NOT operation on `x` and
--  returns the result.
--
-- @param  number(x)
-- @return number
function _:bitwiseNOT(x)
    x = _:assertArgument('x', x, 'number')
    --
    return -x - 1
end

-- _:bitwiseOR(x, y)
-- Perform bitwise OR operation on `x` and
--  returns the result.
--
-- @param  number(x)
-- @param  number(y)
-- @return number
function _:bitwiseOR(x, y)
    x = _:assertArgument('x', x, 'number')
    y = _:assertArgument('y', y, 'number')
    --
    local bx  = _:padStart(_:dec2Bin(x), 32, '0')
    local by  = _:padStart(_:dec2Bin(y), 32, '0')
    local cx  = _:words(bx, '.')
    local cy  = _:words(by, '.')
    local out = ''

    for i = 1, #cx do
        if cx[i] == '1' or cy[i] == '1' then
            out = out .. '1'
        else
            out = out .. '0'
        end
    end

    return _:bin2Dec(out)
end

-- _:bitwiseXOR(x, y)
-- Perform bitwise XOR operation on `x` and
--  returns the result.
--
-- @param  number(x)
-- @param  number(y)
-- @return number
function _:bitwiseXOR(x, y)
    x = _:assertArgument('x', x, 'number')
    y = _:assertArgument('y', y, 'number')
    --
    local bx  = _:padStart(_:dec2Bin(x), 32, '0')
    local by  = _:padStart(_:dec2Bin(y), 32, '0')
    local cx  = _:words(bx, '.')
    local cy  = _:words(by, '.')
    local out = ''

    for i = 1, #cx do
        if cx[i] == '1' then
            out = out .. (cy[i] == '0' and '1' or '0')
        elseif cy[i] == '1' then
            out = out .. (cx[i] == '0' and '1' or '0')
        else
            out = out .. '0'
        end
    end

    return _:bin2Dec(out)
end

-- _:ceil(num, [precision=0])
-- Rounds up `num` to desired `precision`.
--
-- @param  number(num)
-- @param  number(precision)
-- @return number
function _:ceil(num, precision)
    num       = _:assertArgument('num', num, 'number')
    precision = _:assertArgument('precision', precision, 'number', 0)
    --
    local factor = 10 ^ precision

    return _.__ceil(num * factor) / factor
end

-- _:dec2Bin(dec)
-- Converts `dec` representation into it's
--  binary string counterpart.
--
-- @param  number(dec)
-- @return string
function _:dec2Bin(dec)
    dec = _:assertArgument('dec', dec, 'number')
    --
    local hex = _.__format('%x', dec)
    local bin = _:hex2Bin(hex)

    return bin
end

-- _:dec2Hex(dec)
-- Converts `dec` representation into it's
--  hexadecimal string counterpart.
--
-- @param  number(dec)
-- @return string
function _:dec2Hex(dec)
    dec = _:assertArgument('dec', dec, 'number')
    --
    return _.__upper(_.__format('%x', dec))
end

-- _:divide(...)
-- Divides series of numbers and returns result.
--
-- @param  number(...)
-- @return number
function _:divide(...)
    local out

    for k, v in pairs({...}) do
        if _:isNumber(v) then
            if not out then
                out = v
            else
                _:assertNotZero('v', v)
                out = out / v
            end
        end
    end

    return out
end

-- _:floor(num, [precision=0])
-- Rounds down `num` to desired `precision`.
--
-- @param  number(num)
-- @param  number(precision)
-- @return number
function _:floor(num, precision)
    num       = _:assertArgument('num', num, 'number')
    precision = _:assertArgument('precision', precision, 'number', 0)
    --
    local factor = 10 ^ precision

    return _.__floor(num * factor) / factor
end

-- _:hex2Bin(hex)
-- Converts `hex` representation into it's
--  binary string counterpart.
--
-- @param  string(bin)
-- @return string
function _:hex2Bin(hex)
    hex = _:assertArgument('hex', hex, 'string')
    --
    local bin = ''

    for v in _.__gmatch(hex, '.') do
        bin = bin .. _.HB[_.__lower(v)]
    end

    return bin
end

-- _:hex2Dec(hex)
-- Converts `hex` representation into it's
--  base-10 numeric counterpart.
--
-- @param  string(bin)
-- @return number
function _:hex2Dec(hex)
    hex = _:assertArgument('hex', hex, 'string')
    --
    return _:bin2Dec(_:hex2Bin(hex))
end

-- _:max(...)
-- Finds max value in sequence of numbers.
--
-- @param  number(...)
-- @return number
function _:max(...)
    return _:maxBy({...})
end

-- _:maxBy(tabl, [iteratee])
-- Finds max in sequence of numbers, with
--  every element invoked by `iteratree`.
--
-- note:
--  every element of `tabl` will invoke
--  `iteratree`, if provided
--
-- @param  table(tabl)
-- @param  function(iteratee)  - func to ivoke per element
-- @return number
function _:maxBy(tabl, iteratee)
    tabl     = _:assertArgument('tabl', tabl, 'table')
    iteratee = _:assertArgument('iteratee', iteratee, 'function', _.D['iteratee'])
    --
    local max

    for k, v in pairs(tabl) do
        local value = iteratee(v)

        if _:isNumber(value) then
            if not max then
                max = value
            else
                max = _.__max(max, value)
            end
        end
    end

    return max
end

-- _:mean(...)
-- Computes mean of sequence of numbers.
--
-- @param  number(...)
-- @return number
function _:mean(...)
    return _:meanBy({...})
end

-- _:mean(tabl, [iteratee])
-- computes mean of numbers in `tabl`
--
-- note:
--  every element of `tabl` will invoke
--  `iteratree`, if provided
--
-- @param  table(tabl)
-- @param  function(iteratee)  - func to ivoke per element
-- @return number
function _:meanBy(tabl, iteratee)
    tabl     = _:assertArgument('tabl', tabl, 'table')
    iteratee = _:assertArgument('iteratee', iteratee, 'function', _.D['iteratee'])
    --
    local size = _:size(tabl)

    if size > 0 then
        return (_:sumBy(tabl, iteratee) / size)
    end

    return 0
end

-- _:min(...)
-- Computes minimum of sequence of numbers.
--
-- @param  number(...)
-- @return number
function _:min(...)
    return _:minBy({...})
end

-- _:minBy(tabl, [iteratee])
-- Computes minimum of `tabl` of numbers,
--  with every element invoked by `iteratree`.
--
-- note:
--  every element of `tabl` will invoke
--  `iteratree`, if provided
--
-- @param  table(tabl)
-- @param  function(iteratee)  - func to ivoke per element
-- @return number
function _:minBy(tabl, iteratee)
    tabl     = _:assertArgument('tabl', tabl, 'table')
    iteratee = _:assertArgument('iteratee', iteratee, 'function', _.D['iteratee'])
    --
    local min

    for k, v in pairs(tabl) do
        local value = iteratee(v)

        if _:isNumber(value) then
            if not min then
                min = value
            else
                min = _.__min(min, value)
            end
        end
    end

    return min
end

-- _:multiply(...)
-- Multiplies sequence of numbers.
--
-- @param  number(...)
-- @return number
function _:multiply(...)
    return _:multiplyBy({...})
end

-- _:multiply(...)
-- Multiplies series of numbers, with every
--  element invoked by `iteratree`.
--
-- Note: Every element of `tabl` will invoke
--  `iteratree`, if provided.
--
-- @param  mixed(...)
-- @return number
function _:multiplyBy(tabl, iteratee)
    tabl     = _:assertArgument('tabl', tabl, 'table')
    iteratee = _:assertArgument('iteratee', iteratee, 'function', _.D['iteratee'])
    --
    local mul

    for k, v in pairs(tabl) do
        local value = iteratee(v)

        if _:isNumber(value) then
            if not mul then
                mul = value
            else
                mul = mul * value
            end
        end
    end

    return mul
end

-- _:round(num, [precision=0])
-- Computes `value` rounded to `precision`.
--
-- @param  number(num)
-- @param  number(precision)
-- @return number
function _:round(num, precision)
    num       = _:assertArgument('num', num, 'number')
    precision = _:assertArgument('precision', precision, 'number', 0)
    --
    local factor = 10 ^ precision

    return _.__floor(num * factor + 0.5) / factor
end

-- _:subtract(...)
-- Subtracts sequence of numbers
--
-- @param  number(...)
-- @return number
function _:subtract(...)
    return _:subtractBy({...})
end

-- _:subtractBy(tabl, iteratee)
-- Subtracts `tabl` of numbers, with every
--  element invoked by `iteratree`.
--
-- note:
--  every element of `tabl` will invoke
--  `iteratree`, if provided
--
-- @param  table(tabl)
-- @param  function(iteratee)  - func to ivoke per element
-- @return number
function _:subtractBy(tabl, iteratee)
    tabl     = _:assertArgument('tabl', tabl, 'table')
    iteratee = _:assertArgument('iteratee', iteratee, 'function', _.D['iteratee'])
    --
    local sub

    for k, v in pairs(tabl) do
        local value = iteratee(v)

        if _:isNumber(value) then
            if not sub then
                sub = value
            else
                sub = sub - value
            end
        end
    end

    return sub
end

-- _:sum(...)
-- Sums sequence of numbers.
--
-- @param  number(...)
-- @return number
function _:sum(...)
    return _:sumBy({...})
end

-- _:sumBy(tabl, [iteratee])
-- computes sum of all values in `tabl`
--
-- note:
--  every element of `tabl` will invoke
--  `iteratree`, if provided
--
-- @param  table(tabl)
-- @param  function(iteratee)  - func to ivoke per element
-- @return number
function _:sumBy(tabl, iteratee)
    tabl     = _:assertArgument('tabl', tabl, 'table')
    iteratee = _:assertArgument('iteratee', iteratee, 'function', _.D['iteratee'])
    --
    local sum = 0

    for k, v in pairs(tabl) do
        local value = iteratee(v)

        if _:isNumber(value) then
            sum = sum + value
        end
    end

    return sum
end

-- _:toDeg(rad)
-- Converts `rad` to degrees.
--
-- @param  number(rad) - radians
-- @return number
function _:toDeg(rad)
    return _.__deg(rad)
end

-- _:toRad(deg)
-- Converts `deg` to radians.
--
-- @param  number(deg) - degrees
-- @return number
function _:toRad(deg)
    return _.__rad(deg)
end
