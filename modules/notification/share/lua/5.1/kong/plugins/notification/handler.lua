local BasePlugin = require 'kong.plugins.base_plugin'
local NotificationHandler = BasePlugin:extend()

local count =0
local sock


function NotificationHandler:init_worker(config)
   local sockettable
   NotificationHandler.super.init_worker(self)
   print("\nIN INIT>>>>\n")
   -- local counter = ngx.shared.counter;
   -- counter:set("req", 0)
   count = count+1
   print("\ncount in init:",count,"\n")
   ngx.sleep(2)
end


function NotificationHandler:new()
 NotificationHandler.super.new(self, "notification")
end

local socket_url = require "socket.url"

local function parse_url(url)
  local parsed_url = socket_url.parse(url)
  if not parsed_url.port then
    if parsed_url.scheme == "http" then
      parsed_url.port = 80
    elseif parsed_url.scheme == "https" then
      parsed_url.port = 443
    end
  end
  if not parsed_url.path then
    parsed_url.path = "/"
  end
  return parsed_url
 end



-- before sending the message we need to create it
local cjson = require "cjson"

local string_format = string.format
local cjson_encode = cjson.encode

local function get_message(config,parsed_url)
  local url
  if parsed_url.query then
    url = parsed_url.path .. "?" .. parsed_url.query
  else
    url = parsed_url.path
  end

--ngx is a table that stores per request Lua context data 
-- body is encoded consumer if exists and API tables
local body = 
  cjson_encode(
    {
      consumer = ngx.ctx.authenticated_consumer,
      api = ngx.ctx.api
    }
  )


local headers = string_format("%s %s HTTP/1.1\r\nHost: %s\r\nConnection: Keep-Alive\r\nContent-Type: application/json\r\nContent-Length: %s\r\n",config.method:upper(),url,parsed_url.host,#body)

return string_format("%s\r\n%s",headers,body)
end



local function get_message_async(config,parsed_url,data)
  local url
  if parsed_url.query then
    url = parsed_url.path .. "?" .. parsed_url.query
  else
    url = parsed_url.path
  end

--ngx is a table that stores per request Lua context data 
-- body is encoded consumer if exists and API tables
local body = 
  cjson_encode(
    {
      mydata = data
    }
  )


local headers = string_format("%s %s HTTP/1.1\r\nHost: %s\r\nConnection: Keep-Alive\r\nContent-Type: application/json\r\nContent-Length: %s\r\n",config.method:upper(),url,parsed_url.host,#body)
return string_format("%s\r\n%s",headers,body)
end



function send(premature, config,ctx,data)
  -- implement content
  if premature then
    return
  end

 local parsed_url = parse_url(config.url)
 local host = parsed_url.host
 local port = tonumber(parsed_url.port)
 

 ngx.log(ngx.CRIT, cjson_encode({mydata = data}));
 sock = ngx.ctx.sock

-- send the message
 if not sock then
   print("\nCREATE SOCKET\n")
   sock = ngx.socket.tcp() -- creates socket
   ngx.ctx.sock = sock

   sock:settimeout(config.timeout)  -- to be c alled before connect 
   ok,err = sock:connect(host,port)
   if not ok then
    ngx.log(ngx.ERR,"[notification.log] failed to connect to " .. host .. ":" .. tostring(port) .. ": ",err)
    return
   end
 

 else
   print("\nSOCKET THERE\n")
 end


  bytesok,err = sock:send(get_message_async(config,parsed_url,data))
  print("\nPORT:\n",port)
  print("\nbytes sent async:\n",bytesok)
  if not bytesok then
    print("\nZZZZ\n")
    ngx.log(ngx.ERR,"[notification.log] failed to send data " .. host .. ":" .. tostring(port) .. ": ",err)
  end
  -- ngx.log(ngx.INFO,"\n[notification.log] message sent" .. host .. ":" .. tostring(port) .. ": \n") 
  print(string.format("\nHERE1 %s %s \n",host,port))
  print(string_format("\n my message: \n %s \n",get_message_async(config,parsed_url,data)))

  ok, err = sock:setkeepalive(config.keepalive)
  if not ok then
    ngx.log(ngx.ERR,"[notification.log] failed to keep alive " .. host .. ":" .. tostring(port) .. ": ",err)
    return
  end


end


function NotificationHandler:access(config)
 NotificationHandler.super.access(self)

 local parsed_url = parse_url(config.url)
 local host = parsed_url.host
 local port = tonumber(parsed_url.port)


print("\nICI\n")
count = count+1
print("\ncount in access:",count,"\n")


-- special case for SSL
 if parsed_url.scheme == "https" then
   local  _,err = sock:sslhandshake(true, host , false)
   if err then
     ngx.log(ngx.ERR,"[notification.log] failed to do SSL " .. host .. ":" .. tostring(port) .. ": ",err)
   end
 end
 print("\nMESSAGE:\n")
 print(get_message(config,parsed_url))
 print("\n Message printed\n")

  local data = {request={}, response={}}
 

  local req = data["request"]
  local resp = data["response"]
  req["host"] = ngx.var.host
  req["uri"] = ngx.var.uri
  req["headers"] = ngx.req.get_headers()
  req["time"] = ngx.req.start_time()
  req["method"] = ngx.req.get_method()
  req["get_args"] = ngx.req.get_uri_args()


  -- req["post_args"] = ngx.req.get_post_args()
  ngx.req.read_body()
  req["body"] = ngx.req.get_body_data() --ngx.var.request_body

 --content_type = getval(ngx.var.CONTENT_TYPE, "")

  resp["headers"] = ngx.resp.get_headers()
  resp["status"] = ngx.status
  resp["duration"] = ngx.var.upstream_response_time
  resp["time"] = ngx.now()
  resp["body"] = ngx.var.response_body

  -- keep in memory the bodies for this request
  ngx.ctx.runscope = {
    request = data.request,
    response = data.response
  }
  print("\n My body is:\n")
  print(req["body"])


  --look for config
  print("look at status\n")
  status,i,j = pcall(string.find,req["body"],"\"config\":")
  print("\nretour de find: \n")
  print(i,j,status,"\n")
  if status then
    print("\n",i," ",j,"\n")
    i,j,v = string.find(req["body"],"\"config\":\"(.-)\"")
    print("\n",i," ",j," ",v,"\n")

    --retrieve the config
    -- to start from index n in string use string.sub(a,n,-1)
    value = string.match(req["body"],"\"config\":\"(.-)\"")
    print("\n",value,"\n")
    --add it as a header
    ngx.header["FoundConf"] = value 
    print("\nBody printed\n")
  else
    print("\nNO CONFIG\n")
  end
end


function NotificationHandler:body_filter(config)
  -- Eventually, execute the parent implementation
  -- (will log that your plugin is entering this context)
  NotificationHandler.super.body_filter(self)

   count = count+1
   print("\ncount in body filter:",count,"\n")

   local chunk = ngx.arg[1]
   print("\nCHUNK: ",chunk)
   local runscope = ngx.ctx.runscope
   local runscope_data_body = runscope.response.body or ""
   runscope_data_body = runscope_data_body..chunk
   ngx.ctx.runscope.response.body = runscope_data_body  


  --local resp_body = string.sub(ngx.arg[1],1,1000)
  --ngx.ctx.buffered = string.sub((ngx.ctx.buffered or "") .. resp_body,1,1000)
  if ngx.arg[2] then
    print("\nOuah:\n",runscope.response.body) --ngx.ctx.buffered)

    -- Implement any custom logic here
    response = {
      status = ngx.status,
      headers = ngx.resp.get_headers(),
      size = ngx.var.bytes_sent,
      req_body = ngx.var.request_body,
      res_body = ngx.ctx.runscope.response.body,  --ngx.ctx.buffered,
      time = ngx.now(),
      duration = ngx.var.upstream_response_time
    }

   runscope.response = response
   local bytesok, err = ngx.timer.at(0, send, config,ctx,runscope) --response)
   if not bytesok then
    print("\nNOT OK\n")
    ngx.log(ngx.ERR," failed to create timer: ",err)
    return
  end

  end

end

function NotificationHandler:log(config)
  -- Eventually, execute the parent implementation
  -- (will log that your plugin is entering this context)
  NotificationHandler.super.log(self)

  -- local req_times = ngx.shared.counter:get("req");
  -- ngx.shared.counter:set("req", req_times + 1)

  -- Implement any custom logic here

  response = {
   status = ngx.status,
   headers = ngx.resp.get_headers(),
   size = ngx.var.bytes_sent,
   req_body = ngx.var.request_body,
   test = ngx.ctx.buffered,
  }

 print("\nRECU IN LOG>>........\n",ngx.var.request_body)
 print("\nRESBB: \n",ngx.ctx.buffered)
 count = count+1
 print("\ncount in log:",count,"\n")
 print("\nduration inlog:  ",ngx.var.upstream_response_time," ",ngx.now()," ",ngx.now(),"\n")
end


return NotificationHandler







