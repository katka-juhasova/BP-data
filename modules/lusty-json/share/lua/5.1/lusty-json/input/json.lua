local json = config.json

return {
  handler = function(context)
    pcall(function()
      context.input = json.decode(context.request.body)
    end)
  end,

  options = {
    predicate = function(context)
      if config.default then
        return true
      end

      local content = context.request.headers["content-type"]

      if context.request.body then
        if content then
          return content:find("application/json")
        else
          return true
        end
      end

      return false
    end
  }
}
