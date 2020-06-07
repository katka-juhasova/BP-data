local setfenv = require "lil.polyfills.setfenv"

local DebugLogger = require "lil.DebugLogger"
local Levels = require "lil.Levels"

local buildTablePropertySetter = function(rootTbl, rootIdx, callback)
    if type(callback) ~= "function" then
        callback = function() end
    end

    return setmetatable({},
    {
        __call = function(_, value)
            rootTbl[rootIdx] = value
            callback(value)
        end,
        __index = function(_, index)
            if rootIdx then
                rootTbl[rootIdx] = {}
            end

            return setmetatable({},
            {
                __call = function(_, value)
                    if rootIdx then
                        rootTbl[rootIdx][index] = value
                    else
                        rootTbl[index] = value
                    end 
                    
                    callback(value, index)
                end,
                __index = function(_, subIndex)
                    if rootIdx then
                        rootTbl[rootIdx][index] = rootTbl[index] or {}
                    else
                        rootTbl[index] = rootTbl[index] or {}
                    end

                    return function(value)
                        rootTbl[index][subIndex] = value
                        callback(value, index, subindex)
                    end
                end
            })
        end
    })
end

local appenderCreator = function(config, defaultName, module)
    DebugLogger.log("appender creator declared with defaultName = '%s' and module = '%s'", defaultName, module)

    return function(name)
        name = name or defaultName

        config.appenders = config.appenders or {}
        config.appenders[name] =
        {
            module = module
        }

        DebugLogger.log("appender defined in config DSL with name = '%s' and module = '%s'", name, module)

        return function(appenderConfig)
            config.appenders[name].config = appenderConfig

            DebugLogger.log("config for appender defined in config DSL for appender with name = '%s' and config = '%s'", name, tostring(appenderConfig))
        end
    end
end

local runAppenderGenerators = function(appenderGenerators)
    if type(appenderGenerators) ~= "table" then
        return
    end

    DebugLogger.log("appender generators defined in config DSL")

    for _, appenderGenerator in ipairs(appenderGenerators) do
        if type(appenderGenerator) == "function" then
            appenderGenerator()
        end
    end
end

local configPropertySetter = function(config, propertyName)
    DebugLogger.log("config property setter declared in config DSL with config = '%s' and propertyName = '%s'", tostring(config), propertyName)

    return buildTablePropertySetter(config, propertyName, function(value, index, subIndex)
        DebugLogger.log("config property value declared in config DSL with propertyName = '%s' and value = '%s' and index = '%s' and subindex = '%s'", propertyName, tostring(config), tostring(index), tostring(subIndex))
    end)
end

local syntaxSugar = function() end

local buildConfigUsingLoaderDsl = function(loaderFunction)
    local config = {}
    local dslEnv = {
        config = syntaxSugar,
        useLfs = configPropertySetter(config, "useLfs"),
        pattern = configPropertySetter(config, "pattern"),
        minLevel = configPropertySetter(config, "minLevel"),
        maxLevel = configPropertySetter(config, "maxLevel"),
        filter = configPropertySetter(config, "filter"),
        appenders = runAppenderGenerators,
        appender = function(module)
            return appenderCreator(config, module, module)
        end,
        console = appenderCreator(config, "console", "lil.ConsoleAppender"),
        file = appenderCreator(config, "file", "lil.FileAppender"),
        rollingFile = appenderCreator(config, "rollingFile", "lil.RollingFileAppender")
    }

    for level, levelAsInt in pairs(Levels) do
        dslEnv[level] = levelAsInt
    end

    setfenv(loaderFunction, dslEnv)

    local _, err = loaderFunction()

    return config, err
end

return
{
    buildConfigUsingLoaderDsl = buildConfigUsingLoaderDsl
}
