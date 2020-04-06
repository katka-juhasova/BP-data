local DebugLogger = require "lil.DebugLogger"
local OsUtilsConfig = require "lil.OsUtilsConfig"
local StringUtils = require "lil.StringUtils"

local osUtils

local initOsUtils = function()
    if osUtils ~= nil then
        return
    end

    osUtils = require(string.format("lil.%s", OsUtilsConfig.module))
end

local compressFilePath = function(filePath, archiveName, removeFiles, compressionFomat)
    initOsUtils()
    
    return osUtils.compressFilePath(filePath, archiveName, removeFiles, compressionFomat)
end

local getSupportedCompressionFormats = function()
    initOsUtils()
    
    return osUtils.getSupportedCompressionFormats()
end

local directoryExists = function(directoryPath)
    initOsUtils()
    
    return osUtils.directoryExists(directoryPath)
end

local createDirectory = function(directoryPath)
    initOsUtils()
    
    return osUtils.createDirectory(directoryPath)
end

local getFileModificationTime = function(filePath)
    initOsUtils()
    
    return osUtils.getFileModificationTime(filePath)
end

local getFilesForPattern = function(directoryPath, filePattern)
    initOsUtils()
    
    return osUtils.getFilesForPattern(directoryPath, filePattern)
end

local moveFile = function(originalFilePath, newFilePath)
    initOsUtils()
    
    return osUtils.moveFile(originalFilePath, filePattern)
end

local deleteFile = function(filePath)
    DebugLogger.log("delete file with filePath = '%s'", filePath)

    assert(os.remove(filePath))
end

return
{
    compressFilePath = compressFilePath,
    getSupportedCompressionFormats = getSupportedCompressionFormats,
    directoryExists = directoryExists,
    createDirectory = createDirectory,
    getFileModificationTime = getFileModificationTime,
    getFilesForPattern = getFilesForPattern,
    moveFile = moveFile,
    deleteFile = deleteFile
}
