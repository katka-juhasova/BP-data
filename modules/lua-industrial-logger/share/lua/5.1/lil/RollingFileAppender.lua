local DebugLogger = require "lil.DebugLogger"
local FileAppender = require "lil.FileAppender"
local FileUtils = require "lil.FileUtils"
local OsUtils = require "lil.OsUtils"
local StringUtils = require "lil.StringUtils"

local COPY_FORMAT = "copy"
local COPY_FORMAT_EXTENSION = "bak"
local COMPRESSION_FORMATS = OsUtils.getSupportedCompressionFormats()

local RollingFileAppender = function(name, appenderConfig)
    local fileAppender = FileAppender(name, appenderConfig)
    local logFilePath = appenderConfig.logFilePath
    local rolloverConfig = appenderConfig.rollover
    local logFileName
    local maxLogFileSizeInBytes
    local backupFileFormat
    local backupFileExtension
    local maxBackupFiles

    local validateConfig = function()
        DebugLogger.log("validating appender config")

        if type(rolloverConfig) ~= "table" then
            error(("'rollover' configuration table not supplied for Rolling FileAppender '%s'"):format(name))
        end
    
        if type(rolloverConfig.maxFileSizeInKb) ~= "number" then
            error(("'maxFileSizeInKb' is not a number or is missing for RollingFileAppender '%s'"):format(name))
        elseif rolloverConfig.maxFileSizeInKb < 1 then
            error(("'maxFileSizeInKb' for RollingFileAppender '%s' is incorrect, value must be greater than zero"):format(name))
        end

        if StringUtils.isBlank(rolloverConfig.backupFileFormat) then
            error(("'backupFileFormat' for RollingFileAppender '%s' is not a string or missing or blank"):format(name))
        end

        local potentialFormat = rolloverConfig.backupFileFormat:lower()

        if potentialFormat ~= COPY_FORMAT then
            if not COMPRESSION_FORMATS[potentialFormat] then
                error(("'backupFileFormat' value '%s',specified for RollingFileAppender '%s', is not a supported format on the current OS"):format(potentialFormat, name))
            end

            backupFileExtension = COMPRESSION_FORMATS[potentialFormat].extension
        else
            backupFileExtension = COPY_FORMAT_EXTENSION
        end

        backupFileFormat = potentialFormat

        if type(rolloverConfig.maxBackupFiles) ~= "number" then
            error(("'maxBackupFiles' is not a number or is missing for RollingFileAppender '%s'"):format(name)) 
        elseif rolloverConfig.maxBackupFiles < 1 then
            error(("'maxBackupFiles' for RollingFileAppender '%s' is incorrect, value must be greater than zero"):format(name))
        end

        logFileName = FileUtils.getFileName(logFilePath)
        maxLogFileSizeInBytes = rolloverConfig.maxFileSizeInKb * 1000
        maxBackupFiles = rolloverConfig.maxBackupFiles

        DebugLogger.log("validated appender config with backupFileFormat = '%s' and maxLogFileSizeInBytes = '%d' and maxBackupFiles = '%d'", backupFileFormat, maxLogFileSizeInBytes, maxBackupFiles)
    end

    validateConfig()

    local buildBackupFilePath = function(backupIndex, includeFileExtension, returnFilenameOnly)
        DebugLogger.log("build backup file path with logFilePath = '%s' and backupIndex = '%s' and includeFileExtension = '%s'", logFilePath, tostring(backupIndex), tostring(includeFileExtension))
    
        local backupFilePath = StringUtils.concat(logFileName, "-", backupIndex)

        if not returnFilenameOnly then
            backupFilePath = FileUtils.combinePaths(fileAppender.logFileDirectory, backupFilePath)
        end

        if includeFileExtension then
            backupFilePath = string.format("%s.%s", backupFilePath, backupFileExtension)
        end

        DebugLogger.log("build backup file path returning with backupFilePath = '%s'", backupFilePath)

        return backupFilePath
    end

    local getNextBackupFileIndex = function()
        DebugLogger.log("get next backup file index")

        for idx = 1, maxBackupFiles do
            local backupFilePath = buildBackupFilePath(idx, true)

            if not FileUtils.fileExists(backupFilePath) then
                DebugLogger.log("get next backup file index returning with idx = '%d'", idx)
                return idx
            end
        end
    end

    local rolloverLogBackups = function(backupFiles)
        DebugLogger.log("rolling over log file backups with backupFiles = '%s'", tostring(backupFiles))

        local oldestBackupFile
        local oldestBackupFileTimestamp = -1

        for _, backupFile in ipairs(backupFiles) do
            local fileTimestamp = OsUtils.getFileModificationTime(backupFile)

            DebugLogger.log("log file backup '%s' modification time: %d", backupFile, fileTimestamp)

            if oldestBackupFileTimestamp == -1 or oldestBackupFileTimestamp > fileTimestamp then
                oldestBackupFile = backupFile
                oldestBackupFileTimestamp = fileTimestamp
            end
        end

        DebugLogger.log("oldest log file backup '%s' with modification time: %d", oldestBackupFile, oldestBackupFileTimestamp)

        OsUtils.deleteFile(oldestBackupFile)
    end

    local checkIfMaxNumberOfLogBackupsArePresent = function()
        DebugLogger.log("checking if maximum number of backup files reached with logFileName = '%s' and backupFileExtension = '%s' and fileAppender.logFileDirectory = '%s'", logFileName, backupFileExtension, fileAppender.logFileDirectory)

        local maxBackupFilePattern = buildBackupFilePath("*", true, true)
        local backupFilesPresent = OsUtils.getFilesForPattern(fileAppender.logFileDirectory, maxBackupFilePattern)

        maxLogBackupsArePresent = #backupFilesPresent >= maxBackupFiles
    
        DebugLogger.log("check for maximum number of backup files returning with maxLogBackupsArePresent = '%s'", tostring(maxLogBackupsArePresent))
        
        return maxLogBackupsArePresent, backupFilesPresent
    end

    local rolloverLogFile = function()
        DebugLogger.log("rolling over log file")

        local maxLogBackupsArePresent, backupFiles = checkIfMaxNumberOfLogBackupsArePresent()

        if maxLogBackupsArePresent then
            rolloverLogBackups(backupFiles)
        end

        DebugLogger.log("backing up log file with logFilePath = '%s' and backupFilePath = '%s' and backupFileFormat = '%s'", logFilePath, tostring(backupFilePath), backupFileFormat)

        if backupFileFormat ~= COPY_FORMAT then
            OsUtils.compressFilePath(
                logFilePath,
                buildBackupFilePath(getNextBackupFileIndex()), 
                true, 
                backupFileFormat
            )
        else
            OsUtils.moveFile(
                logFilePath,
                buildBackupFilePath(getNextBackupFileIndex(), true)
            )
        end
    end

    local append = function(level, message)
        fileAppender.append(level, message)

        local fileSizeInBytes = FileUtils.getFileSizeInBytes(logFilePath)

        if fileSizeInBytes > maxLogFileSizeInBytes then
            rolloverLogFile()
        end
    end

    return
    {
        append = append,
        name = name,
        config = appenderConfig
    }
end

return RollingFileAppender
