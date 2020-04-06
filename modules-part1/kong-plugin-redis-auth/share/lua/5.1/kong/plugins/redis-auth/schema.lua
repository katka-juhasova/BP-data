local typedefs = require "kong.db.schema.typedefs"


return {
  name = "redis-auth",
  fields = {
    { consumer = typedefs.no_consumer },
    { run_on = typedefs.run_on_first },
    { protocols = typedefs.protocols_http },
    { config = {
        type = "record",
        fields = {
          { key_names = {
              type = "array",
              required = true,
              elements = typedefs.header_name,
              default = { "apikey" },
          }, },
          { hide_credentials = { type = "boolean", default = false }, },
          { anonymous = { type = "boolean", default = false }, },
          { key_in_body = { type = "boolean", default = false }, },
          { run_on_preflight = { type = "boolean", default = true }, },
          { redis_host = typedefs.host({ required = true, default = "localhost" }), },
          { redis_port = typedefs.port({ required = true, default = 6379 }), },
          { redis_key_prefix = { type = "string", default = "redis-auth:" }, },
          { consumer_keys = { 
              type = "array", elements = { type = "string" }, default = { "id" ,"username" ,"custom_id" }
          }, },
        },
    }, },
  },
}