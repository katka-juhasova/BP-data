local Object = require("classic")
local cjson = require("cjson")

local Logger = Object:extend()

local function merge(extendee, extender)
    for key, value in pairs(extender) do
        extendee[key] = value
    end
    
    return extendee
end

function Logger:new()
    if not Logger.ngx then
        error('Nginx is required to construct a logger')
    end

    self._transactionId = Logger.ngx.var.request_id
    self._logCounter = 1
    self._context = {}
end

function Logger.getInstance(nginx)
    if nginx == nil then
        error('Nginx is required to construct a logger')
    else
       Logger.ngx = nginx
    end

    if not Logger.ngx.ctx.logger then
        Logger.ngx.ctx.logger = Logger()
    end

    return Logger.ngx.ctx.logger
end

function Logger:addContext(context)
    self._context = merge(self._context, context)
end

local function getCallerFilePath()
    local debugInfo = debug.getinfo(4, "Sl")
    return debugInfo.source .. ':' .. debugInfo.currentline
end

function Logger:_log(data, severityName, severityCode)
    local additionalData = {
        severity = severityName,
        transaction_id = self._transactionId,
        log_counter = self._logCounter,
        caller_file_path = getCallerFilePath(),
        context = self._context
    }
    local logData = merge(additionalData, data)

    Logger.ngx.log(severityCode, cjson.encode(logData))

    self._logCounter = self._logCounter + 1
end

function Logger:logNotice(data)
    self:_log(data, 'notice', Logger.ngx.NOTICE)
end

function Logger:logWarning(data)
    self:_log(data, 'warning', Logger.ngx.WARN)
end

function Logger:logError(data)
    local error = data

    if type(data) ~= 'table' then
        error = { msg = data }
    end

    self:_log({ error = error }, 'error', Logger.ngx.ERR)
end

function Logger:logInfo(data)
    self:_log(data, 'info', Logger.ngx.INFO)
end

return Logger
