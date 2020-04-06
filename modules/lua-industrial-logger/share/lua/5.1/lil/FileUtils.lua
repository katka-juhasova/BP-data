local DebugLogger = require "lil.DebugLogger"
local OsFacts = require "lil.OsFacts"
local StringUtils = require "lil.StringUtils"

local useFile = function(filePath, mode, useBlock)
    local file = assert(io.open(filePath, mode))

    local useBlockOk, useBlockErrorOrRetVal = xpcall(function() 
        return useBlock(file)
    end, debug.traceback)

    pcall(function()
        file:close()
    end)

    if not useBlockOk then
        error(useBlockErrorOrRetVal)
    end

    return useBlockErrorOrRetVal
end

local appendTextToFile = function(filePath, text)
    DebugLogger.log("appending text to file with filePath = '%s'", filePath)

    return useFile(filePath, "a", function(file)
        return file:write(text)
    end)
end

local getFileSizeInBytes = function(filePath)  
    DebugLogger.log("get file size in bytes with filePath = '%s'", filePath)

    return useFile(filePath, "r", function(file)
        return file:seek("end")
    end)
end

local fileExists = function(filePath)
    DebugLogger.log("checking if file exists with filePath = '%s'", filePath)

    local file, fileOpenError = io.open(filePath)

    pcall(function()
        file:close()
    end)

    return file and not fileOpenError
end

local getFileDirectory = function(filePath)
    DebugLogger.log("get file directory with filePath = '%s'", filePath)

    local lastSeperatorIndex = filePath:match(OsFacts.lastDirectorySeperatorRegex)

    if not lastSeperatorIndex then
        return string.format(".%s", OsFacts.directorySeperator)
    end

    return filePath:sub(0, lastSeperatorIndex)
end

local getFileName = function(filePath)
    DebugLogger.log("get file directory with filePath = '%s'", filePath)

    local lastSeperatorIndex = filePath:match(OsFacts.lastDirectorySeperatorRegex)

    if not lastSeperatorIndex then
        return filePath
    end

    local fileName = StringUtils.replacePatternIfPresent(filePath:sub(lastSeperatorIndex), OsFacts.directorySeperator, "")

    DebugLogger.log("get file directory returning with fileName = '%s'", fileName)

    return fileName
end

local combinePaths = function(left, right)
    DebugLogger.log("combine paths with left = '%s' and right = '%s'", left, right)

    return string.format("%s%s%s", left, OsFacts.directorySeperator, right):gsub(OsFacts.directorySeperatorRegex, OsFacts.directorySeperator)
end

return
{
    useFile = useFile,
    appendTextToFile = appendTextToFile,
    getFileSizeInBytes = getFileSizeInBytes,
    fileExists = fileExists,
    getFileDirectory = getFileDirectory,
    getFileName = getFileName,
    combinePaths = combinePaths
}
