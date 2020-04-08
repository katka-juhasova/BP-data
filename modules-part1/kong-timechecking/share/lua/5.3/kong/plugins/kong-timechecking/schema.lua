local typedefs = require "kong.db.schema.typedefs"

return {
    name = "kong-timechecking",
    fields = {
        {run_on = typedefs.run_on_first},
        {protocols = typedefs.protocols_http},
        {
            config  = {
                type = "record",
                fields = {
                    {
                        attr = {
                            type = "string"
                        }
                    },
                    {
                        methods = {
                            type = "set",
                            elements = {
                                type = "string"
                            }
                        }
                    },
                    {
                        time_expiry = {
                            type = "number"
                        }
                    }
                }
            }
        }
    }
}