local re_match= ngx.re.match

local function validate_ipv4(value)
  if value ~= nil then
    local number = tonumber(value)
    if number ~= nil and value >=0 and value <=255 then
      return true
    end
  end
  return false, string.format("'%s' is not a number in range 0..255", tostring(value))
end

local function validate_ipv6(value)
  if value ~= nil then
    local number = tonumber(value)
    if number ~= nil and value >=0 and value <=9999 then
      return true
    end
  end
  return false, string.format("'%s' is not a number in range 0..9999", tostring(value))
end

return {
  no_consumer = true,
  fields = {
    ipv4_mask = {
      type = "number",
      default = 0,
      func = validate_ipv4
    },
    ipv6_mask = {
      type = "number",
      default = 0,
      func = validate_ipv6
    }
  }
}
