-- If you're not sure your plugin is executing, uncomment the line below and restart Kong
-- then it will throw an error which indicates the plugin is being loaded at least.

--assert(ngx.get_phase() == "timer", "The world is coming to an end!")

local string = require("string")

-- Grab pluginname from module name
local plugin_name = ({...})[1]:match("^kong%.plugins%.([^%.]+)")

-- load the base plugin object and create a subclass
local plugin = require("kong.plugins.base_plugin"):extend()

-- constructor
function plugin:new()
  plugin.super.new(self, plugin_name)
  
  -- do initialization here, runs in the 'init_by_lua_block', before worker processes are forked

end

local function url_reg(url)
  url = url or ""
  local reg_t = {}
  for k in string.gmatch(url, '{{(%S-)}}') do 
    reg_t[k] = true
  end

  return reg_t
end

function plugin:access(plugin_conf)
  plugin.super.access(self)

  local ctx = ngx.ctx
  local uri_captures = ctx.router_matches.uri_captures or {}
  local upstream = ngx.var.upstream_uri

  local reg_t = url_reg(upstream)
  for k in pairs(reg_t) do
    upstream = string.gsub(upstream, '{{' .. k ..'}}', uri_captures[k] or "")
  end
  
  ngx.var.upstream_uri = upstream

end

-- set the plugin priority, which determines plugin execution order
plugin.PRIORITY = 1000

-- return our plugin object
return plugin
