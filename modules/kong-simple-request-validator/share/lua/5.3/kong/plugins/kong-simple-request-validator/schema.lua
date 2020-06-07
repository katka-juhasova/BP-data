local typedefs = require "kong.db.schema.typedefs"
local Schema = require("kong.db.schema")

return {
    name = 'kong-simple-request-validarot',
    fields = {
        { consumer = typedefs.no_consumer },
        {
            config = {
                type = "record",
                fields = {
                    { form_schema = { type = "string", required = false }, },
                    { query_schema = { type = "string", required = false } },
                    { json_schema = { type = "string", required = false } },
                    { updated_at = typedefs.auto_timestamp_ms}
                }
            }
        }
    }

}