local M = {}

function M.areWeRunningInRedis()
  return _G['redis'] ~= nil and _G['redis'].call ~= nil
end

--[[
Change sc from "instanceof stuart.Context" to "instanceof RedisContext extends stuart.Context",
so that it inherits new behavior
--]]
function M.export(sc)
  if M.areWeRunningInRedis() then
    setmetatable(sc, require 'stuart-redis.RedisEmbeddedContext')
  else
    setmetatable(sc, require 'stuart-redis.RedisRemoteContext')
  end
  return sc
end

return M
