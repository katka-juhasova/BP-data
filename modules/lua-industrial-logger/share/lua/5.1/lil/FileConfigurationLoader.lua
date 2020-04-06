local loadstring = require "lil.polyfills.loadstring"

local DebugLogger = require "lil.DebugLogger"
local LoggerConfigurationDsl = require "lil.LoggerConfigurationDsl"
local LoggerFactory = require "lil.LoggerFactory"
local FileUtils = require "lil.FileUtils"
local StringUtils = require "lil.StringUtils"

local CONFIG_FILE_ENV_VAR = "LUA_LOG_CFG_FILE"
local DEFAULT_CONFIG_FILE_PATH = "logger.lua.config"

local executeConfigLoader = function(configLoader)
    DebugLogger.log("executing config loader")

    local fileConfig, configLoaderError = LoggerConfigurationDsl.buildConfigUsingLoaderDsl(configLoader)

    if not fileConfig or configLoaderError then
        error(
            string.format("Error loading logger configuration from file at path '%s': %s\nConfig Lua:\n%s",
                configFilePath, configLoaderError or "unknown error occurred", configFileLua)
        )
    end

    if type(fileConfig) ~= "table" then
        error(
            string.format("Unable to load logger config from file at path '%s': %s defined by config, please declare a table instead", 
                configFilePath, type(fileConfig))
        )
    end

    return fileConfig
end

local buildConfigLoaderForFile = function(configFile)
    DebugLogger.log("building config loader with configFile = '%s'", tostring(configFile))

    local configLua = configFile:read("*all")

    pcall(function() configFile:close() end)
    
    local configLoader, luaLoadError = loadstring(configLua)

    if not configLoader or luaLoadError then
        error(
            string.format("Unable to parse logger config lua from file at path '%s': %s\nConfig Lua:\n%s",
                configFilePath, luaLoadError or "unknown error occurred", configLua)
        )
    end

    DebugLogger.log("build config loader from file with configLoader = '%s' and configLua = '%s'", tostring(configLoader), configLua)

    return configLoader, configLua
end

local openConfigFile = function(configFilePath)
    if not FileUtils.fileExists(configFilePath) and configFilePath == DEFAULT_CONFIG_FILE_PATH then
        DebugLogger.log("ignoring missing default config file with configFilePath = '%s' and DEFAULT_CONFIG_FILE_PATH = '%s'", configFilePath, DEFAULT_CONFIG_FILE_PATH)
        return true
    end

    local configFile, configFileError = io.open(configFilePath)
    
    if not configFile or configFileError then
        error(string.format("Unable to load logger config from file at path '%s': %s", configFilePath, configFileError))
    end

    DebugLogger.log("opened config file with configFilePath = '%s'", configFilePath)

    return false, configFile
end

local getConfigFilePath = function()
    DebugLogger.log("getting config file path with CONFIG_FILE_ENV_VAR = '%s'", CONFIG_FILE_ENV_VAR)

    local envConfigFilePath = os.getenv(CONFIG_FILE_ENV_VAR)

    if envConfigFilePath and StringUtils.isBlank(envConfigFilePath) then
        error(string.format("Unable to load logger config file path from environment variable '%s': value is blank", CONFIG_FILE_ENV_VAR))
    end
    
    DebugLogger.log("loaded config file path with envConfigFilePath = '%s'", tostring(envConfigFilePath))

    return envConfigFilePath
end

local loadConfigFromFile = function(postLoadConfigCallback)
    if type(postLoadConfigCallback) ~= "function" then
        error("parameter 'postLoadConfigCallback' passed to 'loadConfigFromFile' is not a function")
    end

    DebugLogger.log("loadConfigFromFile with postLoadConfigCallback = '%s'", tostring(postLoadConfigCallback))

    local configFilePath = getConfigFilePath() or DEFAULT_CONFIG_FILE_PATH
    local noFileToLoad, configFile = openConfigFile(configFilePath)

    if noFileToLoad then
        return false
    end

    local configLoader, configFileLua = buildConfigLoaderForFile(configFile)
    local fileConfig = executeConfigLoader(configLoader)

    postLoadConfigCallback(fileConfig)

    DebugLogger.log("Loaded logger configuration from file at path '%s':\n%s", configFilePath, configFileLua)
end

return
{
    load = loadConfigFromFile
}
