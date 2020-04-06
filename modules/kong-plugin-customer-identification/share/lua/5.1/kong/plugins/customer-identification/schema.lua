local Errors = require "kong.dao.errors"

return {
    no_consumer = true,
    fields = {
        source_headers = { type = "array", default={} },
        uri_matchers = { type = "array", default={} },
        target_header = { type = "string", required = true },
        source_query_parameter = { type = "string" },
        log_header_mismatch_with = { type = "string" }
    },
    self_check = function(schema, plugin_t, dao, is_update)
        local source_headers_list = type(plugin_t.source_headers) == "table" and plugin_t.source_headers or {}
        local uri_matchers_list = type(plugin_t.uri_matchers) == "table" and plugin_t.uri_matchers or {}

        if #source_headers_list == 0 and #uri_matchers_list == 0 then
            return false, Errors.schema "you must set at least source_headers or uri_matchers"
        end

        return true
    end
}