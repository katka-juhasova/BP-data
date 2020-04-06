local _M = {}

function _M.execute(conf)
  local host = ""
  for i, key in ipairs(conf.host_fields) do
    if string.find(key, "%$") then
      key = key:gsub('[%$]', '')
      key = ngx.var.request_uri:match(key):gsub("/%S+","")
    end
    host = host .. key  
  end
  ngx.req.set_header("host", host)
  ngx.var.upstream_host = host
  ngx.ctx.balancer_address.host = host
end

return _M
