local cjson = require "cjson"
local stringy = require "stringy"
local BasePlugin = require "kong.plugins.base_plugin"
local body_filter = require "kong.plugins.hal.body_filter"

-- PC : 20170217 : Begin
local url = require "kong.plugins.hal.url"
-- PC : 20170217 : End

local HalHandler = BasePlugin:extend()

---------------
-- Constants --
---------------

-- TODO: Enable hal+json
local APPLICATION_HAL_JSON = "application/hal+json"
--local APPLICATION_JSON = "application/json"
local CONTENT_TYPE = "content-type"
local CONTENT_LENGTH = "content-length"

-----------------------
-- Utility functions --
-----------------------

local function get_content_type()
    local header_value = ngx.header[CONTENT_TYPE]
    if header_value then
        return stringy.strip(header_value):lower()
    end
    return nil
end

local function read_response_body()
    local chunk, eof = ngx.arg[1], ngx.arg[2]
    local buffered = ngx.ctx.hal_buffered
    if not buffered then
        buffered = {}
        ngx.ctx.hal_buffered = buffered
    end
    if chunk ~= "" then
        buffered[#buffered + 1] = chunk
        ngx.arg[1] = nil
    end
    if eof then
        local response_body = table.concat(buffered)

        ngx.ctx.hal_buffered = nil
        return response_body
    end
    return nil
end

--- Function which returns a Kong compliant upstream URL.
-- This function returns a Kong compliant upstream URL. 
-- When https protocol is used and no port is defined, Kong (v0.9.3) adds port 443 to the URL; 
-- therefore this function will have to do the same in order to be able to make comparisons.
-- see also : https://github.com/Mashape/kong/issues/869
-- @function get_upstream_url
-- @return kong compliant upstream URL
local function get_upstream_url()
    -- return ngx.ctx.api.upstream_url
    -- Bart VS : return string.gsub(ngx.ctx.api.upstream_url,"https://(.*)/(.*)","https://%1:443/%2");

-- PC : 20170207 : Begin
   local upstream_url = ngx.ctx.api.upstream_url
   local upstream_url_parts = url.parse(upstream_url)
   if upstream_url_parts.scheme == "https" and not upstream_url_parts.port then
      upstream_url = "https://" .. upstream_url_parts.host .. ":443" .. upstream_url_parts.path
      if tostring(upstream_url_parts.query) ~= "" then
         upstream_url= upstream_url .. "?" .. tostring(upstream_url_parts.query)
      end
   end
   return upstream_url
-- PC : 20170207 : End

end


local function get_downstream_url()
    local api = ngx.ctx.api
--[[    for k, v in pairs( api ) do
        ngx.log(ngx.DEBUG, "NGINX context api:" .. k .. "[".. tostring(v) .."]")
    end
    ngx.log(ngx.DEBUG,"---->>" ..  ngx.var.scheme.."://"..ngx.var.host..":"..ngx.var.server_port..ngx.var.request_uri]]

    if api.request_path then
        local request_uri = ngx.var.scheme.."://"..ngx.var.host..":"..ngx.var.server_port..api.request_path
        return request_uri
    end
    return nil
end

---------------------------
-- Plugin implementation --
---------------------------

function HalHandler:new()
    HalHandler.super.new(self, "hal")
end

function HalHandler:header_filter(config)
    HalHandler.super.header_filter(self)
    -- Clear the content length header if the content type is hal+json, because we might change the body.
    if get_content_type() then
        local is_hal_json = stringy.startswith(get_content_type(), APPLICATION_HAL_JSON)
        if is_hal_json then
            ngx.header[CONTENT_LENGTH] = nil
        end
    end
end

function HalHandler:body_filter(config)
    HalHandler.super.body_filter(self)
    if get_content_type() then
        local is_hal_json = stringy.startswith(get_content_type(), APPLICATION_HAL_JSON)
        if is_hal_json then
            local body = read_response_body()
            ngx.log(ngx.DEBUG, "Upstream url:" .. get_upstream_url())
            ngx.log(ngx.DEBUG, "Downstream url:" .. get_downstream_url())
            if body then
                ngx.arg[1] = body_filter.execute(body, get_upstream_url(), get_downstream_url())
            end
        end
    end
end

return HalHandler
