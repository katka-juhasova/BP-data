local Schema = require "kong.db.schema"
local Errors = require "kong.dao.errors"

return {
    no_consumer = true,
    fields = {
        rules = {
            type = "array",
            required = true,
            elements = {
                type = "record",
                fields = {
                    { input_headers = { type = "array", elements = { type = "string" } } },
                    { uri_matchers = { type = "array", elements = { type = "string" } } },
                    { input_query_parameter = { type = "string" } },
                    { output_header = { type = "string", required = true } },
                }
            }
        }
    },
    self_check = function(schema, config, dao, is_update)
        local rules = config.rules or {}
        for _, rule in pairs(rules) do
            local input_headers_list = type(rule.input_headers) == "table" and rule.input_headers or {}
            local uri_matchers_list = type(rule.uri_matchers) == "table" and rule.uri_matchers or {}

            if #input_headers_list == 0 and #uri_matchers_list == 0 and not rule.input_query_parameter then
                return false, Errors.schema "you must set at least input_headers or uri_matchers or input_query_parameter"
            end
        end

        return Schema.new(schema):validate(config)
    end
}