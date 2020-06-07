local Logger = require "logger"
local BasePlugin = require "kong.plugins.base_plugin"

local CustomerIdentificationHandler = BasePlugin:extend()

CustomerIdentificationHandler.PRIORITY = 903

function CustomerIdentificationHandler:new()
    CustomerIdentificationHandler.super.new(self, "customer-identification")
end

local function access(conf)
    local headers = kong.request.get_headers()

    if headers[conf['target_header']] then
        return
    end

    for _, source_header in ipairs(conf['source_headers']) do
        if headers[source_header] then
            kong.service.request.set_header(conf['target_header'], headers[source_header])
            return
        end
    end

    local customer_id = kong.request.get_query()[conf['source_query_parameter']]
    if customer_id then
        kong.service.request.set_header(conf['target_header'], customer_id)
        return
    end

    for _, pattern in ipairs(conf['uri_matchers']) do
        local customer_id = string.match(ngx.var.request_uri, pattern)
        if customer_id then
            kong.service.request.set_header(conf['target_header'], customer_id)
            return
        end
    end
end

local function log_header_mismatch(conf)
    local target_header = tostring(kong.request.get_header(conf.target_header))
    local consistency_header = tostring(kong.request.get_header(conf.log_header_mismatch_with))

    if target_header ~= consistency_header then
        Logger.getInstance(ngx):logWarning({
            msg = ("Header identification mismatch between '%s' and '%s'"):format(conf.target_header, conf.log_header_mismatch_with),
            identification_expected = target_header,
            identification_actual = consistency_header
        })
    end
end

function CustomerIdentificationHandler:access(conf)
    CustomerIdentificationHandler.super.access(self)

    access(conf)

    if conf.log_header_mismatch_with and conf.log_header_mismatch_with ~= "" then
        log_header_mismatch(conf)
    end
end

return CustomerIdentificationHandler
