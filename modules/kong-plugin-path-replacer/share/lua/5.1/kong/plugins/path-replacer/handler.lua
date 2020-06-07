local BasePlugin = require "kong.plugins.base_plugin"

local PathReplacerHandler = BasePlugin:extend()

PathReplacerHandler.PRIORITY = 801

function PathReplacerHandler:new()
  PathReplacerHandler.super.new(self, "path-replacer")
end

function PathReplacerHandler:access(conf)
  PathReplacerHandler.super.access(self)

  local replacement = kong.request.get_header(conf.source_header)

  if not replacement then return end

  local original_upstream_uri = conf.log_only and conf.darklaunch_url or ngx.var.upstream_uri

  local upstream_uri = original_upstream_uri:gsub(conf.placeholder, replacement)

  if conf.log_only then
    kong.service.request.set_header("X-Darklaunch-Replaced-Path", upstream_uri)
  else
    kong.service.request.set_path(upstream_uri)
  end
end

return PathReplacerHandler
