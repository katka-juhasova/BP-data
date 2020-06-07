local DebugLogger = require "lil.DebugLogger"

local contains = function(subject, subString)
    return string.find(subject, subString, 1, true)
end

local replacePatternIfPresent = function(subjectString, pattern, replacementOrReplacementGenerator, ...)
    DebugLogger.log("replacing string if present with subjectString = '%s' and pattern = '%s' and replacementOrReplacementGenerator = '%s'", subjectString, pattern, tostring(replacementOrReplacementGenerator))

    if not contains(subjectString, pattern)  then
        return subjectString
    end

    local replacement = replacementOrReplacementGenerator

    if type(replacementOrReplacementGenerator) == "function" then
        replacement = replacementOrReplacementGenerator(...)
    end

    return subjectString:gsub(
        string.format("%%%s", pattern),
        replacement
    )
end

local trim = function(subject)
    DebugLogger.log("trimming with subject = '%s'", subject)

    return (subject:gsub("^%s+", ""):gsub("%s+$", ""))
end

local isString = function(subject)
    DebugLogger.log("checking is string with subject = '%s'", subject)

    return type(subject) ~= "string" 
end

local isBlank = function(subject)
    DebugLogger.log("checking is blank with subject = '%s'", tostring(subject))

    return type(subject) ~= "string" or trim(subject) == ""
end

local explodeString = function(subject, seperator)
    DebugLogger.log("exploding string with subject = '%s' and seperator = '%s'", subject, seperator)

    local strings = {}

    for str in string.gmatch(subject, seperator) do
        table.insert(strings, trim(str))
    end

    return strings
end

local concat = function(...)
    DebugLogger.log("concating strings")

    local result = ""    

    for _, str in ipairs({...}) do
        result = ("%s%s"):format(result, str)
    end

    DebugLogger.log("concat string returning with result = '%s'", result)

    return result
end

return
{
    contains = contains,
    replacePatternIfPresent = replacePatternIfPresent,
    trim = trim,
    isString = isString,
    isBlank = isBlank,
    explodeString = explodeString,
    concat = concat
}
