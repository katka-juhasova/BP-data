local DIRECTORY_SEPERATOR = package.config:sub(1, 1)

local osIsUnixLikeResult

local osIsUnixLike = function()
    if type(osIsUnixLikeResult) ~= "boolean" then
        osIsUnixLikeResult = DIRECTORY_SEPERATOR == "/"
    end

    return osIsUnixLikeResult
end

return
{
    osIsUnixLike = osIsUnixLike,
    directorySeperator = DIRECTORY_SEPERATOR,
    directorySeperatorRegex = ("[%s]+"):format(DIRECTORY_SEPERATOR),
    lastDirectorySeperatorRegex = ([[^.*()%s]]):format(DIRECTORY_SEPERATOR)
}
