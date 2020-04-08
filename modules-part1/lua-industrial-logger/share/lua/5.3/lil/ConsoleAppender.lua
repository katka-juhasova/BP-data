local AnsiDecoratedStringBuilder = require "lil.AnsiDecoratedStringBuilder"
local DebugLogger = require "lil.DebugLogger"
local StringUtils = require "lil.StringUtils"

local ConsoleAppender = function(name, appenderConfig)
    local config = appenderConfig or {}
    local outputStream

    local validateConfig = function()
        DebugLogger.log("validating configuration for appender with name = '%s' and config = '%s'", name, tostring(config))

        local outputStreamName = not StringUtils.isBlank(config.stream) and config.stream or "stdout"

        outputStream = io[outputStreamName]

        if not outputStream then
            error(
                string.format("Unable to set stream for ConsoleAppender '%s': '%s' is not a standard output stream",
                    name,
                    outputStreamName
                )
            )
        end

        DebugLogger.log("validated configuration for appender with name = '%s' and config = '%s' and outputStream = '%s'", name, tostring(config), tostring(outputStream))
    end

    validateConfig()

    local append = function(level, logMessage)
        local colourConfig = config.colours

        if colourConfig then
            DebugLogger.log("applying colour to log message for appender with name = '%s'", name)

            if type(colourConfig.forLevels) == "table" then
                colourConfig = colourConfig.forLevels[level]
            end

            logMessage = AnsiDecoratedStringBuilder(logMessage)
                .modifier(colourConfig.format)
                .foregroundColour(colourConfig.foreground)
                .backgroundColour(colourConfig.background)
                .build()
        end

        outputStream:write(logMessage)
    end
    
    return
    {
        append = append,
        name = name,
        config = config
    }
end

return ConsoleAppender
