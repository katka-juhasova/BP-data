local typedefs = require "kong.db.schema.typedefs"


return {
  name = "o2acl",
  fields = {
    { consumer = typedefs.no_consumer },
    { run_on = typedefs.run_on_first },
    { protocols = typedefs.protocols_http },
    { config = {
        type = "record",
        fields = {
          { whitelist = { type = "array", elements = { type = "string" }, }, },
          { blacklist = { type = "array", elements = { type = "string" }, }, },
        }
      }
    }
  },
  entity_checks = {
    { only_one_of = { "config.whitelist", "config.blacklist" }, },
    { at_least_one_of = { "config.whitelist", "config.blacklist" }, },
  },
}
