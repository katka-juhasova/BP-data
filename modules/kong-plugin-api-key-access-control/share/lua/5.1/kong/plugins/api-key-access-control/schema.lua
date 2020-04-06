local Schema = require "kong.db.schema"
local Errors = require "kong.dao.errors"

return {
  fields = {
    api_keys = { type = "array", elements = { type = "string" }, required = true },
    whitelist = { type = "array", elements = { type = "string" }, default = {} }
  },
  self_check = function(schema, config, _, _)
    if #config.api_keys == 0 then
      return false, Errors.schema "you must set at least one api key"
    end
    return Schema.new(schema):validate(config)
  end
}