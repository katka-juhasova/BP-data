local loadstring = require "lil.polyfills.loadstring"

local DebugLogger = require "lil.DebugLogger"
local Levels = require "lil.Levels"
local LoggerFactory = require "lil.LoggerFactory"
local OsUtilsConfig = require "lil.OsUtilsConfig"
local StringUtils = require "lil.StringUtils"

local CONFIG_LOADER_ENV_VAR = "LUA_LOG_CFG_LOADER"
local DEFAULT_PATTERN = "%{iso8601}d [%t] %l %n - %m"
local DEFAULT_CONFIG_LOADER = "lil.FileConfigurationLoader"

local loggerConfig = nil

local setConfig = function(config)
    if not config then
        error("nil argument 'config' passed to setConfig")
    end

    if tostring(config.useLfs) == "yes" then
        OsUtilsConfig.config = "LuaOsUtils"
    end

    local appenders = {}

    for appenderName, appenderConfig in pairs(config.appenders) do
        DebugLogger.log("Loading appender with name = '%s' and type = '%s'", appenderName, appenderConfig.module)

        appenders[appenderName] = require(appenderConfig.module)(appenderName, appenderConfig.config)
    end

    config.appenders = appenders

    loggerConfig = config
end

local initConfig = function(configFieldsToSet)
    if configFieldsToSet and type(configFieldsToSet) ~= "table" then
        error("optional argument 'configFieldsToSet' passed to 'loadConfig' requires a table value")
    end

    local config = {
        pattern = DEFAULT_PATTERN,
        appendNewlines = true,
        maxLevel = Levels.TRACE,
        appenders =
        {
            console =
            {
                module = "lil.ConsoleAppender"
            }
        }
    }

    if configFieldsToSet then
        for field, value in pairs(configFieldsToSet) do
            DebugLogger.log("Setting logger config field with name = '%s' and value = '%s'", field, tostring(value))

            config[field] = value
        end
    end

    setConfig(config)
end

local executeConfigLoader = function()
    local envConfigLoader = os.getenv(CONFIG_LOADER_ENV_VAR)

    if envConfigLoader and StringUtils.isBlank(envConfigLoader) then
        error(string.format("Unable to get logger config loader from environment variable '%s': value is blank", CONFIG_LOADER_ENV_VAR))
    end

    local configLoader = envConfigLoader or DEFAULT_CONFIG_LOADER
    local configLoaderLua = string.format("return require('%s')", configLoader)

    DebugLogger.log("Loading configuration with configLoaderLua = '%s'", configLoaderLua)

    local getConfigLoader, loadError = loadstring(configLoaderLua)

    if not getConfigLoader or loadError then
        error(loadError or "unknown error occurred")
    end

    getConfigLoader().load(initConfig)
end

local initConfigIfNeeded = function()
    if loggerConfig then
        return
    end

    local _, loadError = xpcall(executeConfigLoader, debug.traceback)

    if loggerConfig then
        return
    end

    initConfig()

    local logger = LoggerFactory.getLogger("LoggerConfiguration")

    if loadError then
        logger.error("Error loading logger configuration: %s\nAs a fallback, logger configuration has been loaded from defaults", 
            loadError)

        return
    end

    DebugLogger.log("Loaded logger configuration from defaults")
end

local getConfig = function()
    initConfigIfNeeded()

    return loggerConfig
end

return 
{
    getConfig = getConfig,
    setConfig = setConfig,
    initConfigIfNeeded = initConfigIfNeeded
}
