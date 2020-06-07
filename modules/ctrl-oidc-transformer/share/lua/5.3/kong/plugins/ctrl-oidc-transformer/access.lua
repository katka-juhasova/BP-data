local _M = {}
local ngx_set_header = ngx.req.set_header
local req_get_headers = ngx.req.get_headers
local cjson = require("cjson")


function _M.execute(conf)
  
  if req_get_headers()[conf.input_header_name] then
    ngx.log(ngx.INFO, "found "..conf.input_header_name.." header and transforming...")
    local decoded_text = ngx.decode_base64(req_get_headers()[conf.input_header_name])
    local userObj = cjson.decode(decoded_text)
    ngx_set_header(conf.output_header_name, userObj[conf.property_to_pick])
  else
    ngx.log(ngx.ERR, conf.input_header_name.." header unavaiable")
  end

end



return _M