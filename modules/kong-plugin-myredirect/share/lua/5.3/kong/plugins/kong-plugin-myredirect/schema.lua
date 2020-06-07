local utils = require "kong.tools.utils"
local function code_valide(given_value, given_config)
  -- Custom validation
  if given_value > 100  and given_value < 500 then
    return false, "code value is invalid."
  end
end
return {
  no_consumer = true, -- this plugin will only be applied to Services or Routes,
  fields = {
    http_code1 = {
      type = "table",
      schema = {
        fields = {
          code = {type = "number", enum = {301, 302}, func = code_valide, default = 301},
          host = {type = "string", default = ''}
        }
      }
    },
    http_code2 = {
      type = "table",
      schema = {
        fields = {
          code = {type = "number", enum = {301, 302}, func = code_valide, default = 302},
          host = {type = "string", default = ''}
        }
      }
    }
  },
  self_check = function(schema, plugin_t, dao, is_updating)
    -- perform any custom verification
    return true
  end
}