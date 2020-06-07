local json = config.json

return {
  handler = function(context)
    context.response.headers["content-type"] = "application/json"
    if config.empty_as_array then
      if type(context.output) == 'table' and next(context.output) == nil then
        return context.response.send('[]')
      end
    end
    context.response.send(json.encode(context.output))
  end,

  options = {
    predicate = function(context)

      if context.output == nil then
        return false
      end

      if config.default then
        return true
      end

      local accept = context.request.headers.accept
      local content = context.request.headers["content-type"]

      return (accept and (accept:find("application/json") or accept:find("*/*"))) or
             (content and content:find("application/json") and not accept)
    end
  }
}
