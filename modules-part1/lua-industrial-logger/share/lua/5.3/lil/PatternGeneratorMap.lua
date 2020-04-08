local DebugLogger = require "lil.DebugLogger"
local ThreadUtils = require("lil.ThreadUtils")

local PATTERN_GENERATOR_MAP = 
{
    ["%{iso8601}d"] = function() 
        DebugLogger.log("building ISO 8601 format date for pattern")

        local utcDateTime = os.date("!*t")

        return string.format("%04d-%02d-%02dT%02d:%02d:%02dZ", 
            utcDateTime.year, utcDateTime.month, utcDateTime.day,
            utcDateTime.hour, utcDateTime.min, utcDateTime.sec)
    end,

    ["%d"] = function()
        DebugLogger.log("building default locale format date for pattern")

        return os.date("%c")
    end,

    ["%t"] = function() 
        return ThreadUtils.getCurrentThreadId() 
    end,

    ["%l"] = function(level)
        return ("%-5s"):format(string.upper(level))
    end,

    ["%n"] = function(_, loggerName, creator)
        return loggerName or creator
    end
}

return PATTERN_GENERATOR_MAP
