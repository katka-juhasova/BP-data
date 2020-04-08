--
-- Util Functions
--
local __len    = string.len
local __type   = type
local __unpack = unpack


-- _:copy(value)
-- Create deep copy of `value`.
--
-- @param  mixed(value)
-- @return mixed
function _:copy(value)
    -- TODO:
    --   http://lua-users.org/wiki/CopyTable
    --   https://gist.github.com/tylerneylon/81333721109155b2d244
    if not _:isTable(value) then
        return value
    end

    local out = {}

    for k, v in pairs(value) do
        if v == 'table' then
            rawset(out, k, _:copy(v))
        else
            rawset(out, k, v)
        end
    end

    return out
end

-- _:defaultTo(value, default)
-- Sets `value` to `default`, only if `value` not set
--
-- @param  mixed(value)
-- @param  mixed(default)
-- @return mixed
function _:defaultTo(value, default)
    if _:isNil(value) then
        return default
    end

    return value
end

-- _:flow(...)
-- Create a function to invoke `...` functions,
--  one after the other, piping data each subsequent
--  invocation.
--
-- @param  function(...)
-- @return mixed
-- function _:flow(...)
--     -- TODO:
-- end

-- _:flowRight(...)
-- Similar to _:flow(...), except invocations
--  happen right to left.
--
-- @param  function(...)
-- @return mixed
-- function _:flowRight(...)
--     -- TODO:
-- end




-- _:size(value)
-- Calculates size of `value`.
--
-- @param  mixed(value)
-- @return number
function _:size(value)
    local dt = __type(value)

    if dt == 'string' then return __len(value) end
    if dt == 'number' then return value        end
    if dt == 'table'  then
        local size = 0
        for k, v in pairs(value) do size = size + 1 end
        return size
    end
    --TODO: what about the others??
    return nil
end
