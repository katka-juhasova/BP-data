local cjson = require "cjson"

local function claim_check(value, conf)
  local valid_types = {
    ["string"]  = true,
    ["boolean"] = true,
		["number"]  = true,
		["array"] = true
  }

  for k,v in pairs(value) do
    local type = type(v)
    if not valid_types[type] or type == cjson.null then
      return false, "'claims."..k.."' is not one following types: [boolean, string, number, array]"
    end

    return true, nil
  end
end

return {
  no_consumer = true,
  fields = {
		uri_param_names = {type = "array", default = {"jwt"}},
		-- claims = { type = "table", default = {}, func = claim_check }
    claims = { type = "table", default = {}, schema = {
			fields = {
				scope = {type = "array", default= {""}}
			}}, func = claim_check }
  }
}