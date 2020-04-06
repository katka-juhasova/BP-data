
-- stolen from cloudflare's resty.cookie
local ok, new_tab = pcall(require, "table.new")
if not ok then
    new_tab = function() return {} end
end

local ok, clear_tab = pcall(require, "table.clear")
if not ok then
    clear_tab = function(tab) for k, _ in pairs(tab) do tab[k] = nil end end
end

-- end stolen

local _M = new_tab(0, 7)
_M._VERSION = '0.1.1-2'


local ck = require "resty.cookie"
local redis = require "resty.redis"

function _M.new(self, redis_conn, cookie_name, redis_prefix)
    local cookie, err = ck:new()
    if not cookie then
        return nil, err
    end
    if not cookie_name then
        cookie_name = "session"
    end
    if not redis_prefix then
        redis_prefix = "resty_shared_session"
    end
    sess_cookie, err = cookie:get(cookie_name)
    if not sess_cookie then
        return nil, err
    end

    local clen = string.len(sess_cookie)
    if clen ~= 64 then
        return nil, "session cookie is wrong length."
    end

    local _sid = string.sub(sess_cookie, 0, 36)
    local _signature = string.sub(sess_cookie, 38, -1)

    return setmetatable({
        _redis_conn=redis_conn,
        _session_cookie=sess_cookie,
        _sid = _sid,
        _signature = _signature,
        _redis_prefix = redis_prefix,
        _verified = false,
        _data = nil
    }, {__index = self })
end


local function get_redis_signature_key(prefix, sid)
    return prefix .. ":signature:" .. sid
end

local function get_redis_groups_key(prefix, sid)
    return prefix .. ":groups:" .. sid
end

function _M.verify_signature(self)
    local key = get_redis_signature_key(self._redis_prefix, self._sid)
    local actual_sig, err = self._redis_conn:get(key)
    if not actual_sig then
        ngx.log(ngx.ERR, err)
        return nil, err
    end
    local sig_str = tostring(actual_sig)
    if not sig_str then
        return nil, "bad signature value"
    end
    if sig_str == self._signature then
        return true, nil
    end
    return nil, "signatures did not match!"
end

function _M.get_cookie_sid(self)
    return self._sid, nil
end

function _M.get_cookie_signature(self)
    return self._signature, nil
end

function _M.get_cookie_raw(self)
    return self._session_cookie, nil
end

function _M.list_allowed_groups(self)
    local key = get_redis_groups_key(self._redis_prefix, self._sid)
    local data, err = self._redis_conn:smembers(key)
    return data, err
end

function _M.is_group_member(self, group)
    local allowed, err = self:list_allowed_groups()
    if not allowed then
        return nil, err
    end
    for _, ns_name in pairs(allowed) do
        if ns_name == group then
            return true, nil
        end
    end
    return nil, "not allowed"
end

return _M

