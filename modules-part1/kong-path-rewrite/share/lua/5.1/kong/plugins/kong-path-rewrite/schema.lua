local typedefs = require "kong.db.schema.typedefs"

return {
  name = 'request-url-rewrite',
  fields = {
    {
      config = {
        type = 'record',
        fields = {
          {
            rewritePath = {
              type = "string",
              required = true,
            }
          },
        },
      },
    },
  },
}