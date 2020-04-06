local typedefs = require "kong.db.schema.typedefs"

return {
  name = "uppercase-response",
  fields = {
    { protocols = typedefs.protocols_http },
    { config = {
        type = "record",
        fields = {},
      },
    },
  },
}
