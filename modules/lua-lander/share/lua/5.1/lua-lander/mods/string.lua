----------------------
--------------------
-- String Functions
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

-- _:camelCase(str)
-- Converts `str` to [Camel Case](https://en.wikipedia.org/wiki/Camel_case).
--
-- @param  string(str)
-- @return string
function _:camelCase(str)
    str = _:assertArgument('str', str, 'string')
    --
    local words = _:words(_.__lower(str))
    local out   = ''

    for idx, word in pairs(words) do
        out = out .. (idx == 1 and word or _:capitalize(word))
    end

    return out
end

-- _:capitalize(str)
-- Capitalizes first character of `str`
--  and lower cases the rest.
--
-- @param  string(str)
-- @return string
function _:capitalize(str)
    str = _:assertArgument('str', str, 'string')
    --
    str = _.__lower(str)                      -- lower case entire string
    str = _.__gsub(str, '%f[%a]%a', _.__upper)  -- perform capitalize

    return str
end

-- _:endsWith(str, target, [position=_:size(str)])
-- Determines if `str` ends with `target` up until
--  the end `position`.
--
-- @param  string(str)
-- @return boolean
function _:endsWith(str, target, position)
    str      = _:assertArgument('str', str, 'string')
    target   = _:assertArgument('target', target, 'string')
    position = _:assertArgument('position', position, 'number', _:size(str))
    --
    local substr = _.__sub(str, 0, position)

    return _.__find(substr, target) == _:size(substr)
end

-- _:kebabCase(str)
-- Converts `str` to [Kebab Case](https://en.wikipedia.org/wiki/Letter_case#Special_case_styles).
--
-- @param  string(str)
-- @return string
function _:kebabCase(str)
    str = _:assertArgument('str', str, 'string')
    --
    str = _.__gsub(str, '%f[%u]', ' ')  -- separate uppercase transitions
    str = _.__lower(str)                -- lower case entire string

    return _:join(_:words(str), '-')  -- join `words` with `-`
end

-- _:lowerCase(str)
-- Converts `str` to lower-case, space-separated words.
--
-- @param  string(str)
-- @return string
function _:lowerCase(str)
    str = _:assertArgument('str', str, 'string')
    --
    str = _.__gsub(str, '%f[%u]', ' ')  -- separate uppercase transitions
    str = _.__lower(str)                -- lower case entire string

    return _:join(_:words(str), ' ')  -- join `words` with `-`
end

-- _:lowerFirst(str)
-- Lower-cases first character in `str`.
--
-- @param  string(str)
-- @return string
function _:lowerFirst(str)
    str = _:assertArgument('str', str, 'string')
    --
    return _.__gsub(str, '^%a', _.__lower)
end

-- _:pad(str, [length=0], [chars=" "])
-- Pads both sides of `str` with `chars`,
--  only if `str` is smaller than `length`.
--
-- @param  string(str)
-- @param  number(length)
-- @param  string(chars)
-- @return string
function _:pad(str, length, chars)
    str    = _:assertArgument('str', str, 'string')
    length = _:assertArgument('length', length, 'number', 0)
    chars  = _:assertArgument('chars', chars, 'string', ' ')
    --
    local padSize  = length - _.__len(str)
    local halfSize = padSize / 2
    local left     = ""
    local right    = ""

    -- if we need to pad, split pad size 1/2
    if padSize > 0 then
        chars = _.__rep(chars, padSize)
        left  = _.__sub(chars, 1, _.__floor(halfSize))
        right = _.__sub(chars, 1, _.__ceil(halfSize))
    end

    return left .. str .. right
end

-- _:padEnd(str, [length=0], [chars=" "])
-- Pads end of `str` with `chars`, only if
--  `str` is smaller than `length`.
--
-- @param  string(str)
-- @param  number(length)
-- @param  string(chars)
-- @return string
function _:padEnd(str, length, chars)
    str    = _:assertArgument('str', str, 'string')
    length = _:assertArgument('length', length, 'number', 0)
    chars  = _:assertArgument('chars', chars, 'string', ' ')
    --
    chars = _.__rep(chars, length)
    chars = _.__sub(chars, 1, length - _.__len(str))

    return str .. chars
end

-- _:padStart(str, [length=0], [chars=" "])
-- Pads beginning of `str` with `chars`, only
--  if `str` is smaller than `length`.
--
-- @param  string(str)
-- @param  number(length)
-- @param  string(chars)
-- @return string
function _:padStart(str, length, chars)
    str    = _:assertArgument('str', str, 'string')
    length = _:assertArgument('length', length, 'number', 0)
    chars  = _:assertArgument('chars', chars, 'string', ' ')
    --
    chars = _.__rep(chars, length)
    chars = _.__sub(chars, 1, length - _.__len(str))

    return chars .. str
end

-- _:rep(str, [n=1])
-- Repeats given `str` `n` number of times.
--
-- @param  string(str)
-- @return string
function _:rep(str, n)
    str = _:assertArgument('str', str, 'string')
    n   = _:assertArgument('n', n, 'number', 1)
    --
    return _.__rep(str, n)
end

-- _:replace(str, pattern, [repl=""], [n])
-- Replaces matches from `pattern` in `str`
--  with `repl` string.
--
-- @param  string(str)
-- @param  string(pattern)
-- @param  string(repl)     - replacement string
-- @param  number(n)        - n-th capture in pattern
-- @return string
function _:replace(str, pattern, repl, n)
    str     = _:assertArgument('str', str, 'string')
    pattern = _:assertArgument('pattern', pattern, 'string')
    repl    = _:assertArgument('repl', repl, 'string', '')
    --
    return _.__gsub(str, pattern, repl, n)
end

-- _:snakeCase(str)
-- Converts `str` to [Snake Case](https://en.wikipedia.org/wiki/Snake_case).
--
-- @param  string(str)
-- @return string
function _:snakeCase(str)
    str = _:assertArgument('str', str, 'string')
    --
    -- maybe inefficient, but easy to follow..
    str = _.__gsub(str, '(.%f[%u])', '%0_')  -- convert uppercase transitions to `_`
    str = _.__gsub(str, '[%p%s]+', '_')      -- convert punctuations to `_`
    str = _:trim(str, '_')                   -- trim leading/trailing `_` chars

    return _.__lower(str)                    -- lower-case string
end

-- _:split(str, [separator='[^-]'], [limit=_:size(str)])
-- Splits `str` by `separator`, truncated by `limit`.
--
-- @param  string(str)
-- @return table
function _:split(str, separator, limit)
    str       = _:assertArgument('str', str, 'string')
    separator = _:assertArgument('separator', separator, 'string', '%s+')
    --
    local elements = _:words(str, '[^' .. separator .. ']')
    local length   = _:size(elements)
    --
    limit = _:assertArgument('limit', limit, 'number', length)
    --
    return _:drop(elements, length - limit)
end

-- _:startCase(str)
-- Converts `str` to [Start Case](https://en.wikipedia.org/wiki/Letter_case#Stylistic_or_specialised_usage).
--
-- @param  string(str)
-- @return string
function _:startCase(str, target, position)
    str = _:assertArgument('str', str, 'string')
    --
    str = _.__gsub(str, '%f[%u]', ' ')  -- separate uppercase transitions

    local words = _:words(str)
    local out   = ''

    for idx, word in pairs(words) do
        if idx == 1 then
            out = out .. _:upperFirst(word)
        else
            out = out .. ' ' .. _:upperFirst(word)
        end
    end

    return out
end

-- _:startsWith(str, target, [position=1])
-- Determine if `str` starts with `target`,
--  starting at `position`.
--
-- @param  string(str)
-- @param  string(target)
-- @param  number(position)
-- @return string
function _:startsWith(str, target, position)
    str      = _:assertArgument('str', str, 'string')
    target   = _:assertArgument('target', target, 'string')
    position = _:assertArgument('position', position, 'number', 1)
    --
    return _.__find(_.__sub(str, position), target) == 1
end

-- _:toLower(str)
-- Converts entire `str` to lower case.
--
-- @param  string(str)
-- @return string
function _:toLower(str)
    str = _:assertArgument('str', str, 'string')
    --
    return _.__lower(str)
end

-- _:toUpper(str)
-- Converts entire `str` to upper case.
--
-- @param  string(str)
-- @return string
function _:toUpper(str)
    str = _:assertArgument('str', str, 'string')
    --
    return _.__upper(str)
end

-- _:trim(str, [pattern='%s+'])
-- Removes leading and trailing `pattern` of `str`.
--
-- @param  string(str)
-- @param  string(pattern)
-- @return string
function _:trim(str, pattern)
    str = _:trimStart(str, pattern)
    str = _:trimEnd(str, pattern)

    return str
end

-- _:trimEnd(str, [pattern='%s+'])
-- Removes trailing `pattern` of `str`.
--
-- @param  string(str)
-- @param  string(pattern)
-- @return string
function _:trimEnd(str, pattern)
    str     = _:assertArgument('str', str, 'string')
    pattern = _:assertArgument('pattern', pattern, 'string', '%s+')
    --
    if _:isRegexPattern(pattern) then
        return _:replace(str, pattern .. '$', '')
    else
        return _:replace(str, '[' .. pattern .. ']+$', '')
    end
end

-- _:trimStart(str, [pattern='%s+'])
-- Removes leading `pattern` or `str`.
--
-- @param  string(str)
-- @param  string(pattern)
-- @return string
function _:trimStart(str, pattern)
    str     = _:assertArgument('str', str, 'string')
    pattern = _:assertArgument('pattern', pattern, 'string', '%s+')
    --
    if _:isRegexPattern(pattern) then
        return _:replace(str, '^' .. pattern, '')
    else
        return _:replace(str, '^[' .. pattern .. ']+', '')
    end
end

-- _:truncate(str, [options])
-- Truncates `str` with `options`.
--
-- options:
-- - number(length=30)       -- truncate length
-- - string(separator)       -- pattern to truncate to
-- - string(omission='...')  -- omitted text symbol
--
-- @param  string(str)
-- @return string
function _:truncate(str, options)
    str = _:assertArgument('str', str, 'string')
    --
    options = {
        length    = _:assertArgument('length', (options and options['length'] or nil), 'number', 30),
        separator = _:assertArgument('separator', (options and options['separator'] or nil), 'string', ''),
        omission  = _:assertArgument('omission', (options and options['omission'] or nil), 'string', '...')
    }
    --
    local separator = options.separator
    local omission  = options.omission
    local length    = options.length - _.__len(omission)

    if not _:isEmpty(separator) then
        local len

        len    = _.__find(str, separator)  -- find first occurrence of `separator`
        len    = len - 1                 -- offset length to exclude match
        str    = _.__sub(str, 1, len)      -- drop end of string after and including pattern
        length = _.__min(length, len)
    end

    str = _.__sub(str, 1, length)
    str = str .. omission

    return str
end

-- _:upperCase(str)
-- Converts `str` to space-separated, upper case string.
--
-- @param  string(str)
-- @return string
function _:upperCase(str)
    str = _:assertArgument('str', str, 'string')
    --
    str = _.__gsub(str, '%f[%u]', ' ')  -- separate uppercase transitions

    local words = _:words(str)

    return _:join(_:map(words, _.__upper), ' ')
end

-- _:upperFirst(str)
-- Converts first character in  `str` to  upper
--  case, leaving the rest untouched.
--
-- @param  string(str)
-- @return string
function _:upperFirst(str)
    str = _:assertArgument('str', str, 'string')
    --
    return _.__gsub(str, '^%a', _.__upper)
end

-- _:words(str, [pattern='%a+'])
-- Converts `str` into table of words, using
--  `pattern` as separator.
--
-- @param  string(str)
-- @param  string(pattern)
-- @return table
function _:words(str, pattern)
    str     = _:assertArgument('str', str, 'string')
    pattern = _:assertArgument('pattern', pattern, 'string', '%a+')
    _:assertIsRegexPattern('pattern', pattern)
    --
    local words = {}

    for match in _.__gmatch(str, pattern) do
        _.__insert(words, match)
    end

    return words
end