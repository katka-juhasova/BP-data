local typedefs = require "kong.db.schema.typedefs"

return {
    name = "kong-signature-and-remove-attr",
    fields = {
        { run_on = typedefs.run_on_first },
        { protocols = typedefs.protocols_http },
        { config = {
            type = "record",
            fields = {
                {signature_secret_key = {
                    type = "string"
                }},
                {remove_attr = {
                    type = "set",
                    elements = { type = "string" },
                    default = {}
                }}
            }
        } }
    }
}