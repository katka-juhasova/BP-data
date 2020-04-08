----------------------
--------------------
-- Array (indexed tables) Functions
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

-- _:chunki(tabl, [size=1])
-- Splits elements of `tabl` into groups of `size`.
--
-- Note:
--  Only returns numeric indexes of `tabl`.
--
-- @param  table(tabl)       - table to process
-- @param  number([size=1])  - length of each chunk
-- @return table
function _:chunki(tabl, size)
    tabl = _:assertArgument('tabl', tabl, 'table')
    size = _:assertArgument('size', size, 'number', 1)
    --
    local out, sub = {}, {}
    local max = #tabl
    --
    for k, v in ipairs(tabl) do
        _.__insert(sub, v)

        if k % size == 0 or k == max then
            _.__insert(out, sub)
            sub = {}  -- reset
        end
    end

    return out
end

-- _:differencei(tabl, other)
-- Creates copy of `tabl`, excluding any same
--  values from `other`.
--
-- Note:
--  Only affects numeric indexes of `tabl`.
--
-- @param  table(tabl)   - table to process
-- @param  table(other)  - compare table
-- @return table
function _:differencei(tabl, other)
    tabl  = _:assertArgument('tabl', tabl, 'table')
    other = _:assertArgument('other', other, 'table')
    --
    local out = _:copy(tabl)
    local ref = {}
    -- create reference table...
    for k, v in ipairs(other) do
        ref[v] = true
    end
    -- ...now exclude
    for k = #tabl, 1, -1 do
        if ref[tabl[k]] then table.remove(out, k) end
    end
    --
    return out
end

-- _:drop(tabl, [n=1])
-- Creates copy of `tabl` dropping `n` x elements
--  from beginning (or ending if `n` is negative).
--
-- Note:
--  Only affects numeric indexes of `tabl`.
--
-- @param  table(tabl)  - table to process
-- @param  number(n)    - number of elements to drop
-- @return table
function _:drop(tabl, n)
    tabl = _:assertArgument('tabl', tabl, 'table')
    n    = _:assertArgument('n', n, 'number', 0)
    --
    local out = _:copy(tabl)
    local cnt = _:abs(n)

    while cnt > 0 do
        if _:isNegative(n) then
            table.remove(out, 1)
        else
            table.remove(out)
        end
        cnt = cnt - 1
    end

    return out
end

-- _:fill(tabl, value, [n=_:size(tabl)], [fromIndex=1])
-- Fills new `tabl` with `n` x `value` starting
--  at `fromIndex`
--
-- Note:
--  Will only affect numerically indexed table
--  elements.
--
-- @param  table(tabl)
-- @param  mixed(value)
-- @param  number(n)
-- @param  number(fromIndex)
-- @return table
function _:fill(tabl, value, n, fromIndex)
    tabl      = _:assertArgument('tabl', tabl, 'table')
    n         = _:assertArgument('n', n, 'number', _:size(tabl))
    fromIndex = _:assertArgument('fromIndex', fromIndex, 'number', 1)
    --
    local out = _:copy(tabl)

    for i = fromIndex, fromIndex + n - 1 do
        if tabl[i] then
            out[i] = value
        else
            table.insert(out, value)
        end
    end

    return out
end

-- _:findIndex(tabl, predicate, [fromIndex=1])
-- Returns first index (starting from `formIndex`)
--  of `tabl` where `predicate` returns a truthy value.
--
-- @param  table(tabl)         - table to fill
-- @param  function(predicate) - function ivoked per element
-- @param  number(fromIndex)   - index to search from
-- @return number
function _:findIndex(tabl, predicate, fromIndex)
    tabl      = _:assertArgument('tabl', tabl, 'table')
    predicate = _:assertArgument('predicate', predicate, 'function')
    fromIndex = _:assertArgument('fromIndex', fromIndex, 'number', 1)
    --
    for k = fromIndex, #tabl do
        local stat, res = _:attempt(predicate, tabl[k], k)

        if stat and _:isTruthy(res) then
            return k
        end
    end
end

-- _:findLastIndex(tabl, predicate, [fromIndex=#tabl])
-- Returns first index (starting from `formIndex` and
--  moving to the left) of `tabl` where `predicate`
--  returns a truthy value.
--
-- @param  table(tabl)         - table to fill
-- @param  function(predicate) - function ivoked per element
-- @param  number(fromIndex)   - index to search from
-- @return number
function _:findLastIndex(tabl, predicate, fromIndex)
    tabl      = _:assertArgument('tabl', tabl, 'table')
    predicate = _:assertArgument('predicate', predicate, 'function')
    fromIndex = _:assertArgument('fromIndex', fromIndex, 'number', #tabl)
    --
    for k = fromIndex, 1, -1 do
        local stat, res = _:attempt(predicate, tabl[k], k)

        if stat and _:isTruthy(res) then
            return k
        end
    end
end

-- _:head(tabl)
-- Returns first indexed value of `tabl`.
--
-- Note:
--  Only affects indexed elements of `tabl`.
--
-- @param  table(tabl)
-- @return mixed
function _:head(tabl)
    tabl = _:assertArgument('tabl', tabl, 'table')
    --
    return _:nth(tabl, 1)
end

-- _:indexOf(tabl, value)
-- Returns index of first occurrence of `value`
--  in `tabl`, checking only numeric-indexes.
--
-- @param  table(tabl)
-- @param  mixed(value)
-- @return table
function _:indexOf(tabl, value)
    tabl = _:assertArgument('tabl', tabl, 'table')
    --
    for k, v in ipairs(tabl) do
        if value == v then
            return k
        end
    end
end

-- _:initial(tabl)
-- Creates copy of `table` including all elements
--  but the tail.
--
-- @param  table(tabl)
-- @param  mixed(value)
-- @return table
function _:initial(tabl)
    tabl = _:assertArgument('tabl', tabl, 'table')
    --
    local out = _:copy(tabl)

    out[#tabl] = nil

    return out
end

-- _:lastIndexOf(tabl, value)
-- Returns index of last occurrence of `value`
--  in `tabl`, checking only numeric-indexes.
--
-- @param  table(tabl)
-- @param  mixed(value)
-- @return table
function _:lastIndexOf(tabl, value)
    tabl = _:assertArgument('tabl', tabl, 'table')
    --
    for k = #tabl, 1, -1 do
        if value == tabl[k] then
            return k
        end
    end
end

-- _:join(tabl, [separator=','])
-- Converts all numeric-indexed elements in `tabl`
--  to string separated by `separator`.
--
-- @param  table(tabl)
-- @param  string(separator)
-- @return table
function _:join(tabl, separator)
    tabl      = _:assertArgument('tabl', tabl, 'table')
    separator = _:assertArgument('separator', separator, 'string', ',')
    --
    return table.concat(tabl, separator)
end

-- _:mapi(tabl, iteratee)
-- Creates copy of `tabl`, invoking
--  `iteratee` on every element.
--
-- Note:
--  Only affects indexed elements of `tabl`.
--
-- @param  table(keys)        - keys table
-- @param  function(iteratee) - values table
-- @return table
function _:mapi(tabl, iteratee)
    tabl     = _:assertArgument('tabl', tabl, 'table')
    iteratee = _:assertArgument('iteratee', iteratee, 'function')
    --
    local out = _:copy(tabl)

    for k, v in ipairs(tabl) do
        out[k] = _:force(iteratee, v, k)
    end

    return out
end

-- _:nth(tabl, [n=0])
-- Returns `n`-th indexed value of `tabl`.
-- Negative `n`-values will count from the right.
--
-- Note:
--  Only affects indexed elements of `tabl`.
--
-- @param  table(tabl)
-- @param  table(tabl)
-- @return mixed
function _:nth(tabl, n)
    tabl = _:assertArgument('tabl', tabl, 'table')
    n    = _:assertArgument('n', n, 'number', 1)
    --
    local pos = _:abs(n)

    if n < 0 then
        pos = #tabl + 1 - pos
    end

    return tabl[pos]
end

-- _:nth(tabl, [n=0])
-- Returns copy of `tabl` reversing order of numeric indexes.
--
-- Note:
--  Only affects indexed elements of `tabl`.
--
-- @param  table(tabl)
-- @param  table(tabl)
-- @return table
function _:reverse(tabl)
    tabl = _:assertArgument('tabl', tabl, 'table')
    --
    local out = {}

    for i = #tabl, 1, -1 do
        table.insert(out, tabl[i])
    end

    return out
end

-- _:shuffle(tabl)
-- Creates copy of `tabl` and shuffles it
--  using [Fisher-Yates shuffle](https://en.wikipedia.org/wiki/Fisher%E2%80%93Yates_shuffle).
--
-- Note:
--  Only affects indexed elements of `tabl`.
--
-- @param  table(tabl)
-- @return mixed
function _:shuffle(tabl)
    tabl = _:assertArgument('tabl', tabl, 'table')
    --
    local out = _:copy(tabl)
    local j

    for i = #out, 2, -1 do
        j = _.__random(i)
        out[i], out[j] = out[j], out[i]
    end

    return out
end

-- _:tail(tabl)
-- Returns last indexed value of `tabl`.
--
-- Note:
--  Only queries indexed elements of `tabl`.
--
-- @param  table(tabl)
-- @return mixed
function _:tail(tabl)
    tabl = _:assertArgument('tabl', tabl, 'table')
    --
    return _:nth(tabl, #tabl)
end

-- _:without(tabl, ...)
-- Creates new table of values from `tabl`
--  excluding all elements with `...` as it's
--  value.
--
-- @param  table(tabl)
-- @return table
function _:without(tabl, ...)
    tabl = _:assertArgument('tabl', tabl, 'table')
    --
    return _:differencei(tabl, {...})
end