return {
  handler = function(context)
    context.response.headers["content-type"] = "text/html"

    context.response.send(context.output)
  end,

  options = {
    predicate = function(context)
      if config.default then
        return true
      end

      local accept = context.request.headers.accept
      local content = context.request.headers["content-type"]

      return ((accept and (accept:find("text/html") or accept:find("*/*"))) or
             (content and content:find("text/html") and not accept)) and
             type(context.output) == "string"
    end
  }
}
