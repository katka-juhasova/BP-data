local DebugLogger = require "lil.DebugLogger"
local StringUtils = require "lil.StringUtils"
local OsFacts = require "lil.OsFacts"

local DEFAULT_COMPRESSION_FORMAT = "zip"
local REDIRECT_OUTPUT = "> %s"
local REDIRECT_ALL_OUTPUT = "> %s 2>&1"

local powershellIsAvailableResult
local powershellVersionDetected

local getPowershellCommand = function(powershellString)
    return ([[powershell -Command "%s"]]):format(powershellString)
end

local getOutputRedirectString = function(redirectAllStreams)
    local nullPath = OsFacts.osIsUnixLike() and "/dev/null" or "NUL"

    DebugLogger.log("getting output redirect string with redirectAllStreams = '%s' and nullPath = '%s'", tostring(redirectAllStreams), nullPath)

    if redirectAllStreams then
        return REDIRECT_ALL_OUTPUT:format(nullPath)
    end

    return REDIRECT_OUTPUT:format(nullPath)
end

local powershellIsAvailable = function()
    if type(powershellIsAvailableResult) ~= "boolean" then

        powershellIsAvailableResult = (os.execute(
            ("where powershell.exe %s"):format(getOutputRedirectString(true))
        ) == 0)
    end

    return powershellIsAvailableResult
end

local getPowershellVersion = function()
    if powershellVersionDetected then
        return powershellVersionDetected
    end

    local version = -1

    if powershellIsAvailable() then
        local powershellVersionCommand = getPowershellCommand(
            "If (Test-Path Variable:PSVersionTable) {exit $PSVersionTable.PSVersion.Major} Else {exit 1}",
            true
        )

        version = os.execute(
            ("%s %s"):format(powershellVersionCommand, getOutputRedirectString(true))
        )
    end

    powershellVersionDetected = version

    DebugLogger.log("get powershell version returning with powershellVersion = '%d'", version)

    return version
end

local assertUnixCommandAvailable = function(command)
    DebugLogger.log("asserting command available with command = '%s'", command)

    assert(
        os.execute(
            ("command -v %s %s"):format(command, getOutputRedirectString(true))
        ), 
        ("unable to find '%s' command"):format(command)
    )
end

local getUnixZipCompressionUtil = function()
    assertUnixCommandAvailable("zip")

    DebugLogger.log("get unix zip compression util")

    return function(file, archiveName, removeFiles)
        local removeFilesFlag = removeFiles and "m" or ""

        DebugLogger.log("calling unix zip compression util with file = '%s' and archiveName = '%s' and removeFiles = '%s' and removeFilesFlag = '%s'", file, archiveName, tostring(removeFiles), removeFilesFlag)

        assert(
            os.execute(("zip -%s9 '%s.zip' '%s' %s"):format(removeFilesFlag, archiveName, file, getOutputRedirectString())), 
            ("error creating zip archive '%s' for file '%s'"):format(archiveName, file)
        )
    end
end

local getUnixTarCompressionUtil = function()
    assertUnixCommandAvailable("tar")

    DebugLogger.log("get unix tar compression util")

    return function(file, archiveName, removeFiles)
        local removeFilesFlag = removeFiles and "--remove-files" or ""

        DebugLogger.log("calling unix tar compression util with file = '%s' and archiveName = '%s' and removeFiles = '%s' and removeFilesFlag = '%s'", file, archiveName, removeFiles, removeFilesFlag)

        assert(
            os.execute(("env GZIP=-9 tar -czf '%s.gz.tar' '%s' %s %s"):format(archiveName, file, removeFilesFlag, getOutputRedirectString(true))), 
            ("error creating tar archive '%s' for file '%s'"):format(archiveName, file)
        )
    end
end

local getPowershellCompressionUtil = function(format)
    if format ~= "zip" then
        error("windows file compression only supports the 'zip' compression format")
    end

    if not powershellIsAvailable() or getPowershellVersion() < 5 then 
        error("windows file compression requires powershell v5 or newer")
    end

    return function(file, archiveName, removeFiles)        
        local zipCommand = getPowershellCommand(("Compress-Archive -Path '%s' -DestinationPath '%s.zip' -CompressionLevel Optimal -Force"):format(file, archiveName))

        DebugLogger.log("calling powershell zip compression util with file = '%s' and archiveName = '%s' and removeFiles = '%s' and removeFilesFlag = '%s'", file, archiveName, removeFiles, removeFilesFlag)

        assert(
            os.execute(("%s %s"):format(zipCommand, getOutputRedirectString(true))),
            ("error creating zip archive '%s' for file '%s'"):format(archiveName, file)
        )

        if removeFiles then
            assert(
                os.remove(file),
                ("error deleting zipped file '%s'"):format(file)
            )
        end
    end
end

local getCompressionUtil = function(format)
    format = format or DEFAULT_COMPRESSION_FORMAT

    if not OsFacts.osIsUnixLike() then
        return getPowershellCompressionUtil(format)
    end

    DebugLogger.log("getting compression util with format = '%s'", format)

    if format == "tar" then
        return getUnixTarCompressionUtil()
    elseif format == "zip" then
        return getUnixZipCompressionUtil()
    end

    error(("unknown compression format: %s'"):format(format))
end

local compressFilePath = function(filePath, archiveName, removeFiles, compressionFomat)
    DebugLogger.log("compressing file path with file = '%s' and archiveName = '%s' and removeFiles = '%s' and compressionFomat = '%s'", filePath, archiveName, tostring(removeFiles), compressionFomat)

    local compressionUtil = getCompressionUtil(compressionFomat)

    compressionUtil(filePath, archiveName, removeFiles)
end

local getSupportedCompressionFormats = function()
    DebugLogger.log("get supported compression formats")

    local supportedFormats = 
    {
        zip =
        {
            extension = "zip"
        }
    }

    if OsFacts.osIsUnixLike() then
        supportedFormats.tar = 
        { 
            extension = "gz.tar"
        }
    end

    return supportedFormats
end

local directoryExists = function(directoryPath)
    DebugLogger.log("checking directory exists with directoryPath = '%s'", directoryPath)

    local commandStatus, _, exitCode = os.execute(([[cd "%s" %s]]):format(directoryPath, getOutputRedirectString(true)))

    return commandStatus and exitCode == 0
end

local createDirectory = function(directoryPath)
    local createMissingPathsFlag = ""

    if OsFacts.osIsUnixLike() then
        createMissingPathsFlag = "-p"
    end

    DebugLogger.log("creating directory with directoryPath = '%s' and createMissingPathsFlag = '%s'", directoryPath, createMissingPathsFlag)

    assert(
        os.execute(([[mkdir %s "%s" %s]]):format(createMissingPathsFlag, directoryPath, getOutputRedirectString())), 
        ("error creating directory at path: %s"):format(directoryPath)
    )
end

local getFileModificationTimeCommand = function(filePath)
    DebugLogger.log("get file modification time command with filePath = '%s'", filePath)

    if OsFacts.osIsUnixLike() then
        return ([[date -r "%s" +%%s]]):format(filePath)
    end

    if not powershellIsAvailable() then
        error("windows file modification time lookup requires powershell")
    end

    return getPowershellCommand([[(Get-Item -Path '%s').LastWriteTime.ToFileTimeUtc()]]):format(filePath)
end

local getFileModificationTime = function(filePath)
    DebugLogger.log("get file modification time with filePath = '%s'", filePath)

    local modificationTimeCommand = getFileModificationTimeCommand(filePath)
    local dateProc, err = io.popen(modificationTimeCommand)

    if not dateProc or err then
        error(("Error getting modification time for file '%s': %s"):format(filePath, err or "unknown error"))
    end

    local utcTimestamp = StringUtils.trim(dateProc:read("*a"))

    pcall(function()
        dateProc:close()
    end)

    DebugLogger.log("read file modification time with filePath = '%s' and utcTimestamp = '%s'", filePath, utcTimestamp)

    return tonumber(utcTimestamp)
end

local getFileListingCommand = function(directoryPath, filePattern)
    DebugLogger.log("get file listing command with directoryPath = '%s' and filePattern = '%s'", directoryPath, filePattern)

    if OsFacts.osIsUnixLike() then
        return ([[echo "%s"%s]]):format(directoryPath, filePattern)
    end

    return ([[for %%f in ("%s\%s") do @echo | set /p=%%f]]):format(directoryPath, filePattern)
end

local getFilesForPattern = function(directoryPath, filePattern)
    DebugLogger.log("getting files with directoryPath = '%s' and filePattern = '%s'", directoryPath, filePattern)

    local fileListingCommand = getFileListingCommand(directoryPath, filePattern)

    DebugLogger.log("getting files with fileListingCommand = '%s'", fileListingCommand)

    local listProc, err = io.popen(fileListingCommand)

    if not listProc or err then
        error(("Error listing files in directory '%s' using pattern '%s': %s"):format(directoryPath, filePattern, err or "unknown error"))
    end

    local filesString = listProc:read("*a")

    DebugLogger.log("result of getting files with directoryPath = '%s' and filePattern = '%s' and filesString = '%s'", directoryPath, filePattern, filesString)

    return StringUtils.explodeString(filesString, "%S+")
end

local getMoveFileCommand = function()
    DebugLogger.log("get move file command")

    if OsFacts.osIsUnixLike() then
        return [[mv -f "%s" "%s"]]
    else
        return [[move /Y "%s" "%s"]]
    end
end

local moveFile = function(originalFilePath, newFilePath)
    DebugLogger.log("move file with originalFilePath = '%s' and newFilePath = '%s'", originalFilePath, newFilePath)

    local moveFileCommand = getMoveFileCommand():format(originalFilePath, newFilePath)
    
    assert(os.execute(moveFileCommand))
end

return
{
    compressFilePath = compressFilePath,
    getSupportedCompressionFormats = getSupportedCompressionFormats,
    directoryExists = directoryExists,
    createDirectory = createDirectory,
    getFileModificationTime = getFileModificationTime,
    getFilesForPattern = getFilesForPattern,
    moveFile = moveFile
}
