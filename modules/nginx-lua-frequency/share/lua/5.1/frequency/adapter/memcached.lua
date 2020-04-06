local Memcached, Memc = require "resty.memcached", {}
local mt = { __index = Memc }

function Memc:connect(host, port, timeout, prefix)
    timeout = timeout or 300
    prefix = prefix or ""
    local Memc, err = Memcached:new()
    if not Memc then
        return false, err
    end

    Memc:set_timeout(timeout)
    local ok, err = Memc:connect(host, port)
    if not ok then
        return false, "memc:connect error: " .. err
    end

    return setmetatable({ Memc = Memc, prefix = tostring(prefix) }, mt)
end

function Memc:get(key)
    key = self:getKey(key)
    local res, flag, err = self.Memc:get(key)
    return res, flag, err
end

function Memc:set(key, value, expire)
    key = self:getKey(key)
    local ok, err = self.Memc:set(key, value, expire)
    if ok == 1 then
        return true, err
    end
    return false, err
end

function Memc:close(max_idle_timeout, pool_size)
    max_idle_timeout = max_idle_timeout or 10000
    pool_size = pool_size or 100
    local ok, err = self.Memc:set_keepalive(max_idle_timeout, pool_size)
    if not ok then
        self.Memc:close()
    end
end

function Memc:getKey(key)
    return self.prefix .. key
end

return Memc