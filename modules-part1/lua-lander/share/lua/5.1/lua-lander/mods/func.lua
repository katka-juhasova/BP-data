----------------------
--------------------
-- Function Functions
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

-- _:attempt(func, ...)
-- Attempts to invoke `func` with `...` args.
--
-- @param  function(func)
-- @return void
function _:attempt(func, ...)
    func = _:assertArgument('func', func, 'function')
    ---
    if _:is_(func) then
        return pcall(_[func], _, ...)
    else
        return pcall(func, ...)
    end
end

-- _:force(func)
-- Same as [_:attempt](#attempt), but doesn't
--  use `pcall`.
--
-- @param  function(func)
-- @return void
function _:force(func, ...)
    func = _:assertArgument('func', func, 'function')
    ---
    if _:is_(func) then
        return _[func](_, ...)
    else
        return func(...)
    end
end

-- _:ifFalsey(func, ...)
-- Intercept [_:attempt](#attempt) by invoking `func`
--  with `...` args, then sending the results to a
--  user-specified callback only if falsey.
--
-- @param  function(func)
-- @param  mixed(...)
-- @return callback
function _:ifFalsey(func, ...)
    func     = _:assertArgument('func', func, 'function')
    callback = _:assertArgument('callback', select('#', ...), 'function')
    ---
    local args      = _:initial({...})
    local stat, res = _:attempt(func, _.__unpack(args))

    if stat and not res then
        return callback(res)
    end
end

-- _:ifTruthy(func, ...)
-- Intercept [_:attempt](#attempt) by invoking `func`
--  with `...` args, then sending the results to a
--  user-specified callback only if truthy.
--
-- @param  function(func)
-- @param  mixed(...)
-- @return callback
function _:ifTruthy(func, ...)
    func     = _:assertArgument('func', func, 'function')
    callback =  _:assertArgument('callback', _:tail({...}), 'function')
    ---
    local args      = _:initial({...})
    local stat, res = _:attempt(func, _.__unpack(args))

    if stat and res then
        return callback(res)
    end
end

-- _:pipe(funcs, ...)
-- Attempts to run a series of `funcs`, starting with
--  args `...`, and passing return values to
--  subsequent function calls.
--
-- @param  function(func)
-- @return string, mixed
-- function _:pipe(funcs, ...)
--     funcs = _:assertArgument('funcs', funcs, 'table')
--     ---
--     local status
--     local result = ...

--     for _k, func in ipairs(funcs) do
--         if _:isFunction(func) then
--             status, result = _:attempt(func, args)

--             -- oops!
--             if not status then error('Error in calling `pipe`: ' .. result) end
--         end
--     end

--     return result
-- end