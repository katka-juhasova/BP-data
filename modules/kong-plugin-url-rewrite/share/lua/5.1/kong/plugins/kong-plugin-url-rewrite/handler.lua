local BasePlugin = require "kong.plugins.base_plugin"

local URLRewriter = BasePlugin:extend()

URLRewriter.PRIORITY = 700

function URLRewriter:new()
  URLRewriter.super.new(self, "url-rewriter")
end

function resolveUrlParams(requestParams, url)
  for paramValue in requestParams do
    local requestParamValue = ngx.ctx.router_matches.uri_captures[paramValue]
    url = url:gsub("<" .. paramValue .. ">", requestParamValue)
  end
  return url
end

function getRequestUrlParams(url)
  return string.gmatch(url, "<(.-)>")
end

function URLRewriter:access(config)
  URLRewriter.super.access(self)
  requestParams = getRequestUrlParams(config.url)
  ngx.var.upstream_uri = resolveUrlParams(requestParams, config.url)
end

return URLRewriter
