local typedefs = require "kong.db.schema.typedefs"


return {
  name = "respond-redirect",
  fields = {
    { run_on = typedefs.run_on_first },
    { protocols = typedefs.protocols_http },
    { config = {
        type = "record",
        fields = {
            { content_type = { type = "string"},},
            { body_400 = { type = "string" }, },
            { body_401 = { type = "string" }, },
            { body_429 = { type = "string" }, },
            { body_500 = { type = "string" }, },
            { body_xxx = { type = "string" }, },
        },
      },
    },
  },
}

