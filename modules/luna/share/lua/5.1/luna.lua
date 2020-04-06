-- luna

local cjson = require('cjson')
local lfs = require('lfs')

local luna = {
  routes = {}
}

function luna.configure(self)
  local config = '/etc/luna/rc.lua'
  local fd = io.open(config, 'r')

  if fd then
    fd:close()
    self.config = dofile(config)
  else
    self.config = {
      endpoints = '/var/lib/luna/endpoints'
    }
  end
end

function luna.init(self)
  self:configure()
  for version in lfs.dir(self.config.endpoints) do
    local module_path = self.config.endpoints .. '/' .. version
    if version ~= '.' and version ~= '..' and lfs.attributes(module_path, 'mode') == 'directory' then
      for endpoint in lfs.dir(module_path) do
        local module_file = module_path .. '/' .. endpoint
        if endpoint ~= '.' and endpoint ~= '..' and lfs.attributes(module_file, 'mode') == 'file' then
          module = dofile(module_file)

          for _, ctx in pairs(module.routes) do
            table.insert(self.routes, {
              uri = '/' .. version .. '/' .. string.gsub(endpoint, '.lua', '') .. ctx.context,
              method = ctx.method,
              func = function() return ctx.call() end
            })
          end
        end
      end
    end
  end

  self:router()
end

function luna.response(self, status, data)
  ngx.header['Content-Type'] = 'application/json'
  ngx.status = status

  if data and type(data) == 'table' then
    ngx.print(cjson.encode(data))
  end
  ngx.exit(ngx.OK)
end

function luna.router(self)
  for _, route in pairs(self.routes) do
    local uri = '^' .. route.uri
    local match = ngx.re.match(ngx.var.uri, uri, 'oi')
    if match and ngx.var.request_method == route.method then
      local status, data = route.func()
      self:response(status, data)
    elseif ngx.var.request_method == 'OPTIONS' then
      -- browser cors implementation sucks
      self:response(ngx.HTTP_OK, nil)
    end
  end
  self:response(ngx.HTTP_NOT_FOUND, nil)
end

luna:init()
