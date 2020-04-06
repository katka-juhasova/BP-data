local DebugLogger = require "lil.DebugLogger"
local IdUtils = require "lil.IdUtils"

local THREAD_ID = IdUtils.generateNonUniqueId()

local getCurrentThreadId = function()
    DebugLogger.log("getting current thread id with THREAD_ID = '%s'", THREAD_ID)
    return THREAD_ID
end

return
{
    getCurrentThreadId = getCurrentThreadId
}
