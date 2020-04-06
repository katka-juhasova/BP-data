local DebugLogger = require "lil.DebugLogger"
local FileUtils = require "lil.FileUtils"
local OsUtils = require "lil.OsUtils"
local StringUtils = require "lil.StringUtils"

local FileAppender = function(name, config)
    local logFileDirectory
    local logDirectoryCreated = false

    local validateConfig = function()
        DebugLogger.log("validating configuration for appender with name = '%s' and config = '%s'", name, tostring(config))
    
        if type(config) ~= "table" then
            error(("configuration table not supplied for FileAppender '%s'"):format(name))
        end

        if StringUtils.isBlank(config.logFilePath) then
            error(("'logFilePath' specified for FileAppender '%s' is missing/blank"):format(name))
        end

        logFileDirectory = FileUtils.getFileDirectory(config.logFilePath)

        if not config.createMissingDirectories and not OsUtils.directoryExists(logFileDirectory) then
            error(("directory '%s' in 'logFilePath' for FileAppender '%s' is missing " ..
                "(set 'createMissingDirectories = true' to automatically create it)"):format(logFileDirectory, name))
        end

        DebugLogger.log("validated configuration for appender with name = '%s' and config = '%s' and logFileDirectory = '%s'", name, tostring(config), logFileDirectory)
    end

    validateConfig()

    local append = function(level, logMessage)
        if config.createMissingDirectories
          and not logDirectoryCreated
          and not OsUtils.directoryExists(logFileDirectory) then
            DebugLogger.log("creating log file directory for appender with name = '%s' and logFileDirectory = '%s'", name, logFileDirectory)

            OsUtils.createDirectory(logFileDirectory)
            logDirectoryCreated = true
        end

        FileUtils.appendTextToFile(config.logFilePath, logMessage)
    end

    return
    {
        append = append,
        name = name,
        config = config,
        logFileDirectory = logFileDirectory
    }
end

return FileAppender
