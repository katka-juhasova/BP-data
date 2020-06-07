local BasePlugin = require "kong.plugins.base_plugin"
local http = require "socket.http"

local cjson =  require "cjson"

local RndpluginHandler = BasePlugin:extend()

function RndpluginHandler:new()
  RndpluginHandler.super.new(self, "rndplugin")
end

function RndpluginHandler:access(conf)
    RndpluginHandler.super.access(self)

    --baca value dari parameter
    self.securityPath = conf.securityMatrixPath
    self.authPath = conf.checkAuthPath

    --check dia authorized apa nggak
    res, code, response_headers, status = http.request{
      url = self.authPath,
      ssl_verify = false,
      method = "GET",
      headers = {
              ["Content-Type"] = "application/json",
              ["Authorization"] = kong.request.get_header("authorization")
          },
      redirect = false
    }

    if code == 401 then
      kong.response.exit(401, "Unauthorized")
    elseif code == 400 then
      kong.response.exit(401, "token not found")
    end
    
end

function RndpluginHandler:header_filter(config)
    RndpluginHandler.super.header_filter(self)
end

function RndpluginHandler:body_filter(config)
  RndpluginHandler.super.body_filter(self)

  --baca body response dari service
  local serviceResponse = ngx.arg[1]
  local response ={}
  
  --kirim POST ke service security matrix dengan payload response dari service dan tambahan header nama service
  local res2, code2, response_headers2, status2 = http.request{
    url = self.securityPath,
    method = "POST",
    headers ={
        ["Content-Type"] = "application/json",
        ["Service-Path"] = kong.request.get_path(),
        ["Content-Length"] = serviceResponse:len()
    },
    source = ltn12.source.string(serviceResponse),
    sink = ltn12.sink.table(response)
  }
  response = table.concat(response)

  if ngx.status < 400 then
  	ngx.arg[1] = response
    ngx.arg[2] = ""
    return
  end
  
end

return RndpluginHandler
