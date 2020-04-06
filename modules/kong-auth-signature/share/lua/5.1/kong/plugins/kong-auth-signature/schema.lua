local typedefs = require "kong.db.schema.typedefs"

return {
    name = "kong-auth-signature",
    fields = {
        { run_on = typedefs.run_on_first },
        { protocols = typedefs.protocols_http },
        { config = {
            type = "record",
            fields = {

                {header_key = {
                    type = "string"
                }},
                {body_key = {
                    type = "string"
                }}, 
                {api_key_1 = {
                    type = "string"
                }},
                {secret_key_1 = {
                    type = "string"
                }},
                {api_key_2 = {
                    type = "string"
                }},
                {secret_key_2 = {
                    type = "string"
                }},
                {api_key_3 = {
                    type = "string"
                }},
                {secret_key_3 = {
                    type = "string"
                }},
                {api_key_4 = {
                    type = "string"
                }},
                {secret_key_4 = {
                    type = "string"
                }},
                {api_key_5 = {
                    type = "string"
                }},
                {secret_key_5 = {
                    type = "string"
                }},
                {
                    secret_signature={
                        type = "string"
                    }
                }
            }
        } }
    }
}