--process config
local parseConfig = function(val)
  local ret = {}
  for k, v in pairs(val) do
    if type(v) == "table" then
      for key, value in pairs(v) do
        v = value
      end
    end
    local channel = {}
    string.gsub(v, "([^:]+)", function(c) channel[#channel+1] = c end)
    ret[#ret+1] = channel
  end
  return ret
end

local prefix = parseConfig(config.prefix)
local suffix = parseConfig(config.suffix)
local status = {}

for k, v in pairs(config.status) do
  status[k] = parseConfig(v)
end

return {
  handler = function(context)

    local code = context.response.status

    local statusCode = status[code] or status[code/100%10]
    for i=1, #prefix do
      context.lusty:publish({unpack(prefix[i])}, context)
    end
    for i=1, #statusCode do
      context.lusty:publish({unpack(statusCode[i])}, context)
    end
    for i=1, #suffix do
      context.lusty:publish({unpack(suffix[i])}, context)
    end
    context.output = nil 
  end,

  options = {
    predicate = function(context)

      if context.error then
        context.response.status = 500
      end

      local code = context.response.status

      --If xxx (eg 503) set OR x00 (eg, 500) code set then
      if status[code] or status[code/100%10] then
        return true
      end
      return false
    end
  }
}
