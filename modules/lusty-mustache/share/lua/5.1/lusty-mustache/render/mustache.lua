local lustache = require "lustache"
local lfs = require "lfs"
local cache = {}

local readAll = function(file)
  if config.base then
    lfs.chdir(config.base)
  end
  local f = io.open(file, "rb")
  content = f:read("*all")
  f:close()

  return content
end

local getFile = function(file, cache)
  local content = cache[file]

  if not content then
    content = readAll(file)
    content = lustache:compile(content)
    cache[file] = content
  end

  return content
end

return {
  handler = function(context)
    context.response.headers["content-type"] = "text/html"

    local partials = {}
    local partialNames = context.template.partials or config.partials or {}
    local templateName = context.template.name or config.template or ''
    local template = getFile(templateName..'.mustache', cache)

    for i,v in pairs(partialNames) do
      partials[i] = getFile(v..'.mustache', cache)
    end

    lustache.renderer.partial_cache = partials
    local content = template(context.output)

    context.output = content
  end,

  options = {
    predicate = function(context)
      local accept = context.request.headers.accept or "text/html"
      local content = context.request.headers["content-type"]

      return ((accept and (accept:find("text/html") or accept:find("*/*"))) or
             (content and content:find("text/html") and not accept)) and
             context.template and context.template.type == "mustache"
    end
  }
}

