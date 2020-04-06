local DebugLogger = require "lil.DebugLogger"
local Levels = require "lil.Levels"
local PatternBuilder = require "lil.PatternBuilder"

local Logger = function(name, creator, loggerConfig)
    local patternBuilder = PatternBuilder(name, creator)
    local defaultPattern = loggerConfig.pattern

    DebugLogger.log("created logger with name = '%s' and creator = '%s' and loggerConfig = '%s'", name, creator, tostring(loggerConfig))

    local buildLogMessageFromAppenderPattern = function(appender, level, formattedMessage)
        DebugLogger.log("building log message with appender = '%s' and level = '%s' and formattedMessage = '%s'", appender.name, level, formattedMessage)

        if type(appender.config) == "table" and appender.config.pattern then
            message = patternBuilder.buildLogMessageFromPattern(appender.config.pattern, level, formattedMessage)
        end
    end

    local buildLogMessageWithPattern = function(level, logMessage)
        return patternBuilder.buildLogMessageFromPattern(defaultPattern, level, logMessage)
    end

    local formatMessage = function(logMessage, ...)
        DebugLogger.log("formatting message with logMessage = '%s'", logMessage)

        local formattedMessage = string.format(logMessage, ...):gsub("%%", "%%%%")

        if loggerConfig.appendNewlines then
            formattedMessage = formattedMessage .. "\n"
        end

        return formattedMessage
    end

    local isLogLevelAccepted = function(config, configName, level)
        if type(config) ~= "table" then
            return nil
        end

        DebugLogger.log("checking if log level is accepted with config = '%s' and configName = '%s' and level = '%s'", tostring(config), configName, level)
    
        local levelAccepted = nil
        
        if type(config.filter) == "function" then
            DebugLogger.log("executing level filter with config.filter = '%s'", config.filter)
 
            local filterStatus, filterError = xpcall(function()
                levelAccepted = (levelAccepted == nil and true or levelAccepted) and config.filter(level)
            end, debug.traceback)

            if not filterStatus then
                error(("Error applying filter in config '%s': %s"):format(configName, filterError))
            end
        elseif type(config.level) == "number" then
            DebugLogger.log("applying level from config with config.level = '%s'", config.level)

            levelAccepted = (levelAccepted == nil and true or levelAccepted) and level == config.level
        else
            if type(config.minLevel) == "number" then
                DebugLogger.log("applying minLevel from config with config.minLevel = '%s'", config.minLevel)

                levelAccepted = (levelAccepted == nil and true or levelAccepted) and level >= config.minLevel
            end
            
            if type(config.maxLevel) == "number" then
                DebugLogger.log("applying maxLevel from config with config.maxLevel = '%s'", config.maxLevel)

                levelAccepted = (levelAccepted == nil and true or levelAccepted) and level <= config.maxLevel
            end
        end
        
        DebugLogger.log("checking if log level is accepted returning with levelAccepted = '%s'", tostring(levelAccepted))
    
        return levelAccepted
    end

    local writeToAppenders = function(level, logMessage, ...)
        DebugLogger.log("writing to appenders with level = '%s' and logMessage = '%s'", level, logMessage)

        local levelValue = Levels.parse(level)
        local configAcceptedLevel = isLogLevelAccepted(loggerConfig, "loggerConfig", levelValue)
        local formattedMessage, defaultPatternMessage 

        for appenderName, appender in pairs(loggerConfig.appenders) do
            local appenderAcceptedLevel = isLogLevelAccepted(appender.config, appenderName, levelValue)

            if appenderAcceptedLevel == nil then
                appenderAcceptedLevel = configAcceptedLevel
            end

            DebugLogger.log("checked if log level accepted by appender with appenderAcceptedLevel = '%s' and appenderName = '%s' and levelValue = '%s'", tostring(appenderAcceptedLevel), appenderName, levelValue)
            
            if appenderAcceptedLevel then
                formattedMessage = formattedMessage or formatMessage(logMessage, ...)
                defaultPatternMessage = defaultPatternMessage or buildLogMessageWithPattern(level, formattedMessage)

                local message = buildLogMessageFromAppenderPattern(appender, level, formattedMessage) or defaultPatternMessage

                appender.append(level:upper(), message)
            end
        end
    end 

    local log = function(level, message, ...)
        writeToAppenders(level, message, ...)
    end

    local logError = function(level, message, err, ...)
        writeToAppenders(level, message, ...)
        writeToAppenders(level, err, ...)
    end

    return setmetatable(
        {
            log = log,
            logError = logError
        },
        {
            __index = function(self, level)
                Levels.parse(level)

                if level:lower() == "off" then
                    DebugLogger.log("logger is turned off, ignoring log call with level = '%s' and name = '%s' and creator = '%s'", level, name, creator)

                    return nil
                end

                return function (message, ...)
                    log(level, message, ...)
                end
            end
        }
    )
end

return Logger
