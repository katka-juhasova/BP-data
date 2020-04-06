
local param = config.param
local header = config.header

return {
  handler = function(context)
    context.request.headers[header] = context.request.query[param]
    return nil, true
  end,

  options = {
    predicate = function(context)
      if context.request.query[param] then
        return true
      end
      return false
    end
  }
}
