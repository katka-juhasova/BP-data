local typedefs = require "kong.db.schema.typedefs"

local ORDERED_PERIODS = {"second", "minute", "hour", "day", "month", "year"}

local function validate_periods_order(config)
  for i, lower_period in ipairs(ORDERED_PERIODS) do
    local v1 = config[lower_period]
    if type(v1) == "number" then
      if getmetatable(config.redis_host) == nil then
        return nil, string.format("redis host must be set if %s is set", lower_period)
      end

      for j = i + 1, #ORDERED_PERIODS do
        local upper_period = ORDERED_PERIODS[j]
        local v2 = config[upper_period]
        if type(v2) == "number" and v2 < v1 then
          return nil, string.format(
            "The limit for %s(%.1f) cannot be lower than the limit for %s(%.1f)",
            upper_period,
            v2,
            lower_period,
            v1
          )
        end
      end
    end
  end

  return true
end

return {
  name = "mithril",
  fields = {
    {consumer = typedefs.no_consumer},
    {
      config = {
        type = "record",
        fields = {
          {url_template = {type = "string", required = true}},
          {
            rules = {
              type = "array",
              elements = {
                type = "record",
                fields = {
                  {
                    path = {
                      type = "string",
                      required = true
                    }
                  },
                  {
                    scopes = {
                      type = "array",
                      required = true,
                      elements = {
                        type = "string"
                      }
                    }
                  },
                  {
                    methods = {
                      type = "array",
                      required = true,
                      elements = {
                        type = "string",
                        one_of = {
                          "GET",
                          "POST",
                          "PUT",
                          "PATCH",
                          "DELETE",
                          "OPTIONS"
                        }
                      }
                    }
                  },
                  {
                    abac = {
                      type = "record",
                      fields = {
                        {
                          action = {
                            type = "string",
                            required = true
                          }
                        },
                        {
                          endpoint = {
                            type = "string",
                            required = true
                          }
                        },
                        {
                          rule = {
                            type = "string",
                            required = true
                          }
                        },
                        {
                          resource = {
                            type = "string",
                            required = true
                          }
                        },
                        {
                          resource_id = {
                            type = "string"
                          }
                        },
                        {
                          contexts = {
                            type = "array",
                            elements = {
                              type = "record",
                              fields = {
                                {
                                  name = {
                                    type = "string",
                                    required = true
                                  }
                                },
                                {
                                  id = {
                                    type = "string",
                                    required = true
                                  }
                                }
                              }
                            }
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          },
          {second = {type = "number", gt = 0}},
          {minute = {type = "number", gt = 0}},
          {hour = {type = "number", gt = 0}},
          {day = {type = "number", gt = 0}},
          {month = {type = "number", gt = 0}},
          {year = {type = "number", gt = 0}},
          {fault_tolerant = {type = "boolean", default = true}},
          {redis_host = typedefs.host},
          {redis_port = typedefs.port({default = 6379})},
          {redis_password = {type = "string", len_min = 0}},
          {redis_timeout = {type = "number", default = 2000}},
          {redis_database = {type = "number", default = 0}},
          {hide_client_headers = {type = "boolean", default = false}},
          {mis_only = {type = "boolean", default = false}}
        },
        custom_validator = validate_periods_order
      }
    }
  }
}
