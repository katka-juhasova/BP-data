local BasePlugin = require "kong.plugins.base_plugin"
local OidcHandler = BasePlugin:extend()
local utils = require("kong.plugins.oidc-adfs.utils")
local filter = require("kong.plugins.oidc-adfs.filter")
local session = require("kong.plugins.oidc-adfs.session")

local cjson = require("cjson")

OidcHandler.PRIORITY = 1000


function OidcHandler:new()
  OidcHandler.super.new(self, "oidc-adfs")
end

function OidcHandler:access(config)
  OidcHandler.super.access(self)
  local oidcConfig = utils.get_options(config, ngx)

  if filter.shouldProcessRequest(oidcConfig) then
    session.configure(config)

    if filter.shouldErrorRequest(oidcConfig) then
      utils.exit(ngx.HTTP_UNAUTHORIZED, "Unauthorized", ngx.HTTP_UNAUTHORIZED)
    else
      handle(oidcConfig)
    end

  else
    ngx.log(ngx.DEBUG, "OidcHandler ignoring request, path: " .. ngx.var.request_uri)
  end

  ngx.log(ngx.DEBUG, "OidcHandler done")
end

function handle(oidcConfig)

  local headers = ngx.req.get_headers()
  local header =  headers['Authorization']
  if header == nil or header:find(" ") == nil then

    local response
    if oidcConfig.introspection_endpoint then
      response = introspect(oidcConfig)
      if response then
        utils.injectUser(response)
      end
    end

    if response == nil then
      response = make_oidc(oidcConfig)

      ngx.req.set_header("Authorization", "Bearer " .. response.access_token)
      ngx.log(ngx.ERR, "BEARER TOKEN: " .. response.access_token)
      if response and response.id_token and oidcConfig.use_id_token_for_userinfo then
        local userinfo = cjson.encode(response.id_token)
        ngx.req.set_header("X-Userinfo", ngx.encode_base64(userinfo))
      end

      if response and response.user then
        utils.injectUser(response.user)
        local userinfo = cjson.encode(response.user)
        ngx.req.set_header("X-Userinfo", ngx.encode_base64(userinfo))
      end
    end
  end
end

function make_oidc(oidcConfig)
  ngx.log(ngx.DEBUG, "OidcHandler calling authenticate, requested path: " .. ngx.var.request_uri)
  local res, err = require("resty.openidc").authenticate(oidcConfig)
  if err then
    if oidcConfig.recovery_page_path then
      ngx.log(ngx.DEBUG, "Entering recovery page: " .. oidcConfig.recovery_page_path)
      ngx.redirect(oidcConfig.recovery_page_path)
    end
    utils.exit(500, err, ngx.HTTP_INTERNAL_SERVER_ERROR)
  end
  return res
end

function introspect(oidcConfig)
  if utils.has_bearer_access_token() or oidcConfig.bearer_only == "yes" then
    local res, err = require("resty.openidc").introspect(oidcConfig)
    if err then
      if oidcConfig.bearer_only == "yes" then
        ngx.header["WWW-Authenticate"] = 'Bearer realm="' .. oidcConfig.realm .. '",error="' .. err .. '"'
        utils.exit(ngx.HTTP_UNAUTHORIZED, err, ngx.HTTP_UNAUTHORIZED)
      end
      return nil
    end
    ngx.log(ngx.DEBUG, "OidcHandler introspect succeeded, requested path: " .. ngx.var.request_uri)
    return res
  end
  return nil
end


return OidcHandler
