----------------------
-- The lugate module.
-- Lugate is a lua module for building JSON-RPC 2.0 Gateway APIs just inside of your Nginx configuration file.
-- Lugate is meant to be used with [ngx\_http\_lua\_module](https://github.com/openresty/lua-nginx-module) together.
--
-- @classmod lugate.cache.cache
-- @author Ivan Zinovyev <vanyazin@gmail.com>
-- @license MIT

local Cache = {}

--- Create new cache instance
-- @param ...
-- @return[type=table] Return cache instance
function Cache:new(...)
end

--- Set value to cache
-- @param[type=string] key
-- @param[type=string] value
-- @param[type=number] ttl

function Cache:set(key, value, ttl)
end

--- Add value to the set
-- @param[type=string] set
-- @param[type=string] key
function Cache:sadd(set, key)
end

--- Get value from cache
-- @param[type=string] key
-- @return[type=string]
function Cache:get(key)
end

return Cache