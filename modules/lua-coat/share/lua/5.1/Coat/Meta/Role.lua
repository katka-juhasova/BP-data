
--
-- lua-Coat : <http://fperrad.github.io/lua-Coat/>
--

local _ENV = nil
local _M = {}

local _roles = {}
local _rolenames = {}
function _M.add_role (name, role)
    _roles[name] = role
    _rolenames[#_rolenames+1] = name
end

function _M.roles ()
    local i = 0
    return  function ()
                i = i + 1
                local name = _rolenames[i]
                local role = _roles[name]
                return name, role
            end
end

function _M.role (name)
    return _roles[name]
end

function _M.attributes (role)
    local i = 0
    return  function ()
                local v
                repeat
                    i = i + 1
                    v = role._STORE[i]
                    if not v then return nil end
                until v[1] == 'has'
                return v[2], v[3]
            end
end

function _M.methods (role)
    local i = 0
    return  function ()
                local v
                repeat
                    i = i + 1
                    v = role._STORE[i]
                    if not v then return nil end
                    local name = v[2]
                until v[1] == 'method' and not name:match '^_build_'
                  and not name:match '^_get_' and not name:match '^_set_'
                return v[2], v[3]
            end
end

return _M
--
-- Copyright (c) 2009-2018 Francois Perrad
--
-- This library is licensed under the terms of the MIT/X11 license,
-- like Lua itself.
--
