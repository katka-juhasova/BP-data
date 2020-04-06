local DEBUG_ENV_VAR_NAME = "LUA_LOG_DEBUG"
local DIRECTORY_SEPERATOR = package.config:sub(1, 1)

local debugLoggingEnabled = false

local log = function(message, ...)
    if not debugLoggingEnabled then
        return
    end

    local formattedMessage = (message):format(...):gsub("\r", [[\r]]):gsub("\n", [[\n]])
    local callingFunctionInfo = debug.getinfo(2)

    local codeLocation = ("[%s:%s]"):format(
        callingFunctionInfo.short_src:gsub("lua[-]industrial[-]logger", "lil")
            :gsub(("[.][%s]"):format(DIRECTORY_SEPERATOR), "")
            :gsub(DIRECTORY_SEPERATOR, ".")
            :gsub("[.]lua", ""),
        callingFunctionInfo.currentline
    )

    print(("%s - %s"):format(codeLocation, formattedMessage))
end

local setDebugLoggingEnabled = function(isEnabled)
    debugLoggingEnabled = isEnabled
end

local checkIfEnabledViaEnvironment = function()
    local debugEnvFlag = os.getenv(DEBUG_ENV_VAR_NAME)

    if debugEnvFlag == nil then
        return
    end
    
    debugEnvFlag = debugEnvFlag:lower()

    if debugEnvFlag == "true" then
        setDebugLoggingEnabled(true)
    end
end

checkIfEnabledViaEnvironment()

return
{
    log = log,
    setDebugLoggingEnabled = setDebugLoggingEnabled
}
