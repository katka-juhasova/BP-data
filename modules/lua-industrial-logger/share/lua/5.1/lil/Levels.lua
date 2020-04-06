local DebugLogger = require "lil.DebugLogger"

local LEVELS =
{
    OFF = 0,
    ERROR = 200,
    WARN = 400,
    INFO = 600,
    DEBUG = 800,
    TRACE = 1000
}

LEVELS.parse = function(level)
    DebugLogger.log("attempting to parse log level with level = '%s'", level)

    return LEVELS[tostring(level):upper()] or error(("Unable to parse log level using string '%s'"):format(tostring(level)))
end

return LEVELS
