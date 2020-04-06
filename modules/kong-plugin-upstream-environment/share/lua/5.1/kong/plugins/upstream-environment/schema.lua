local typedefs = require "kong.db.schema.typedefs"

return {
  name = "upstream-environment",
  --no_consumer = false, -- this plugin is available on APIs as well as on Consumers,
  fields = {
    -- Describe your plugin's configuration's schema here.
    {
      config = {
        type = "record",
        fields = {
          {
            target_environment = {
              type = "string",
              default = "dev"
            },
          },
          {
            replace_environment = {
              type = "string",
              default = "test"
            },
          },
        },
      },
    },
  },

}
