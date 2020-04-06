local function context_check(value)
  local context_fields = {
    name = "string",
    id = "string"
  }

  for k, v in pairs(value) do
    if type(v) ~= "table" then
      return false, "'context." .. (k - 1) .. "' is not a table"
    end

    for key, val in pairs(v) do
      if context_fields[key] == nil then
        return false, "'context." .. (k - 1) .. "." .. key .. "' is not allowed field"
      end
    end

    for key, key_type in pairs(context_fields) do
      if v[key] == nil then
        return false, "'context." .. (k - 1) .. "." .. key .. "' is required"
      end
      if type(v[key]) ~= key_type then
        return false, "'context." .. (k - 1) .. "." .. key .. "' is invalid type. " .. key_type .. " expected"
      end
    end
  end

  return true
end

return {
  no_consumer = true, -- this plugin will only be API-wide,
  fields = {
    action = {type = "string", required = true},
    endpoint = {type = "string", required = true},
    rule = {type = "string", required = true},
    resource = {type = "string", required = true},
    resource_id = {type = "string", required = true},
    contexts = {type = "array", default = {}, func = context_check}
  }
}
