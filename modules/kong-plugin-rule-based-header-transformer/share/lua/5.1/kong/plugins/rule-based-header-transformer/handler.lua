local BasePlugin = require "kong.plugins.base_plugin"

local RuleBasedHeaderTransformerHandler = BasePlugin:extend()

RuleBasedHeaderTransformerHandler.PRIORITY = 904

local function header_filter(filter)
    return kong.request.get_header(filter)
end

local function uri_filter(matcher)
    return string.match(kong.request.get_path(), matcher)
end

local function get_output_value(filter_param_list, filter_func)
    local filter_params = filter_param_list or {}

    for _, filter_param in pairs(filter_params) do
        local output_value = filter_func(filter_param)
        if output_value then
            return output_value
        end
    end
end

local function get_output_value_from_headers(input_headers)
    return get_output_value(input_headers, header_filter)
end

local function get_output_value_from_uri(matchers)
    return get_output_value(matchers, uri_filter)
end

function RuleBasedHeaderTransformerHandler:new()
    RuleBasedHeaderTransformerHandler.super.new(self, "rule-based-header-transformer")
end

function RuleBasedHeaderTransformerHandler:access(conf)
    RuleBasedHeaderTransformerHandler.super.access(self)

    for _, rule in pairs(conf.rules) do
        if not kong.request.get_header(rule.output_header) then
            local output_header_value = get_output_value_from_headers(rule.input_headers)

            if not output_header_value then
                output_header_value = kong.request.get_query()[rule.input_query_parameter]
            end

            if not output_header_value then
                output_header_value = get_output_value_from_uri(rule.uri_matchers)
            end

            if output_header_value then
                kong.service.request.set_header(rule.output_header, output_header_value)
            end
        end
    end

end

return RuleBasedHeaderTransformerHandler
