local DebugLogger = require "lil.DebugLogger"
local IdUtils = require "lil.IdUtils"
local Logger = require "lil.Logger"

local getLogger = function(name)
    local loggerConfig = require("lil.LoggerConfiguration").getConfig()

    local caller = debug.getinfo(2).short_src
    local loggerName = name and name or caller or string.format("{logger-#%s}", IdUtils.generateNonUniqueId())

    DebugLogger.log("Building logger with name = '%s' and caller = '%s'", loggerName, caller)

    return Logger(loggerName, caller, loggerConfig)
end

return 
{
    getLogger = getLogger
}
