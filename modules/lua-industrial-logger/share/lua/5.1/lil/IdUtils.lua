MAX_ID_LENGTH = 10

local DebugLogger = require "lil.DebugLogger"

local generateNonUniqueId = function()
    DebugLogger.log("generateNonUniqueId")

    local threadAddress = tostring({}):sub(10)

    local threadAddressLetters = threadAddress:gsub("%d", "")
    local threadAddressNumbers = threadAddress:gsub("[a-z]", "")

    local threadAddressNumber = tonumber(threadAddressNumbers)
    local maxNumberWidth = MAX_ID_LENGTH - threadAddressLetters:len()
    local maxRandomNumber = tonumber(string.rep("9", maxNumberWidth))

    math.randomseed(os.time() + threadAddressNumber)

    local randomNumber = math.random(maxRandomNumber)
    local idFormatString = string.format("%s%d%s", "%s%0", maxNumberWidth, "d")

    local nonUniqueId = string.format(idFormatString, threadAddressLetters, randomNumber)

    DebugLogger.log("generated non unique ID with nonUniqueId = '%s'", nonUniqueId)

    return nonUniqueId
end

return
{
    generateNonUniqueId = generateNonUniqueId
}
