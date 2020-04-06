local lfs = require "lfs"

local DebugLogger = require "lil.DebugLogger"
local FileUtils = require "lil.FileUtils"
local NativeOsUtils = require "lil.NativeOsUtils"
local OsFacts = require "lil.OsFacts"
local StringUtils = require "lil.StringUtils"

local directoryExists = function(directoryPath)
    local directoryPathAttributes, pathError = lfs.attributes(directoryPath)

    return not pathError and directoryPathAttributes.mode == "directory"
end

local createDirectory = function(directoryPath)
    assert(lfs.mkdir(directoryPath))
end

local getFileModificationTime = function(filePath)
    return assert(lfs.attributes(filePath)).modification
end

local getFilesForPattern = function(directoryPath, rawFilePattern)
    filePattern = StringUtils.replacePatternIfPresent(rawFilePattern, ".", "[.]")
    filePattern = StringUtils.replacePatternIfPresent(filePattern, "-", "[-]")
    filePattern = StringUtils.replacePatternIfPresent(filePattern, "+", "[+]")
    filePattern = StringUtils.replacePatternIfPresent(filePattern, "*", ".*")
    filePattern = StringUtils.replacePatternIfPresent(filePattern, directoryPath, "")
    filePattern = StringUtils.replacePatternIfPresent(filePattern, OsFacts.directorySeperator, "")

    DebugLogger.log("getting files for pattern: raw = '%s' | sanitised = '%s'", rawFilePattern, filePattern)

    matchingFiles = {}

    for file in lfs.dir(directoryPath) do
        if file ~= "." and file ~= ".." then
            if file:match(filePattern) then
                fullFilePath = FileUtils.combinePaths(directoryPath, file)

                DebugLogger.log("file matches pattern '%s': %s", filePattern, fullFilePath)

                table.insert(matchingFiles, fullFilePath)
            end

            DebugLogger.log("file does not match pattern '%s': %s", filePattern, file)
        end
    end

    DebugLogger.log("found %d files for pattern '%s'", #matchingFiles, filePattern)

    return matchingFiles
end

return
{
    compressFilePath = NativeOsUtils.compressFilePath,
    getSupportedCompressionFormats = NativeOsUtils.getSupportedCompressionFormats,
    directoryExists = directoryExists,
    createDirectory = createDirectory,
    getFileModificationTime = getFileModificationTime,
    getFilesForPattern = getFilesForPattern,
    moveFile = NativeOsUtils.moveFile
}
