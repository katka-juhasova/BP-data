
-- Copyright 2016 Niko Usai
-- Modifications Copyright (C) 2019 wanghaoyu@agora.io

--    Licensed under the Apache License, Version 2.0 (the "License");
--    you may not use this file except in compliance with the License.
--    You may obtain a copy of the License at

--        http://www.apache.org/licenses/LICENSE-2.0

--    Unless required by applicable law or agreed to in writing, software
--    distributed under the License is distributed on an "AS IS" BASIS,
--    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
--    See the License for the specific language governing permissions and
-- limitations under the License.

local _M = {}
local cjson = require "cjson.safe"
local pl_stringx = require "pl.stringx"
local http = require "resty.http"
local crypto = require "crypto"

local OAUTH_CALLBACK = "^%s/oauth2/callback(/?(\\?[^\\s]*)*)$"

function _M.run(conf)
  -- Check if the API has a request_path and if it's being invoked with the path resolver
  local path_prefix = ""

  if ngx.ctx.router_matches ~= nil then
    path_prefix = ngx.ctx.router_matches.uri
    if pl_stringx.endswith(path_prefix, "/") then
      path_prefix = path_prefix:sub(1, path_prefix:len() - 1)
    end
  end

  local callback_url = get_callback_url(conf, path_prefix)

  -- check if we're calling the callback endpoint
  if ngx.re.match(ngx.var.request_uri, string.format(OAUTH_CALLBACK, path_prefix)) then
    handle_callback(conf, callback_url)
  else
    local encrypted_token = ngx.var.cookie_EOAuthToken

    if not encrypted_token then
      -- check if token was passed in header
      local headers = kong.request.get_headers()
      if headers.EOAuthToken then
        encrypted_token = headers.EOAuthToken
      end
    end

    -- check if we are authenticated already
    if encrypted_token then
      local access_token = decode_token(encrypted_token, conf)
      if not access_token then
        -- broken access token
        return redirect_to_auth( conf, callback_url )
      end

      local user_info, err = kong.cache:get(access_token, { ttl = conf.user_info_periodic_check }, get_user_info, conf, access_token)

      if err then
        kong.cache:invalidate(access_token)
        kong.log.err("Could not retrieve UserInfo", err)
      end

      -- sanity check, should never reach
      if not user_info then
        kong.log.err("User info is missing")
        redirect_to_auth( conf, callback_url )
      end

      if conf.hosted_domain ~= "" and conf.email_key ~= "" then
        if not pl_stringx.endswith(user_info[conf.email_key], conf.hosted_domain) then
          return kong.response.exit(ngx.HTTP_UNAUTHORIZED, {
            message = "Unauthorized, Hosted domain is not matching"
          })
        end
      end

      for i, key in ipairs(conf.user_keys) do
        kong.service.request.set_header("X-Oauth-".. key, user_info[key])
        kong.response.set_header("X-Oauth-".. key, user_info[key])
      end

      kong.response.set_header("X-Oauth-Token", access_token)

      if type(ngx.header["Set-Cookie"]) == "table" then
        ngx.header["Set-Cookie"] = { "EOAuthUserInfo=0; Path=/;Max-Age=" .. conf.user_info_periodic_check .. ";HttpOnly", unpack(ngx.header["Set-Cookie"]) }
      else
        ngx.header["Set-Cookie"] = { "EOAuthUserInfo=0; Path=/;Max-Age=" .. conf.user_info_periodic_check .. ";HttpOnly", ngx.header["Set-Cookie"] }
      end
    else
      return redirect_to_auth( conf, callback_url )
    end
  end
end

function get_user_info(conf, access_token)

  -- Get user info
  local httpc = http:new()
  local res, err = httpc:request_uri(conf.user_url, {
    method = "GET",
    ssl_verify = false,
    headers = {
      ["Authorization"] = "Bearer " .. access_token,
    }
  })

  if res then
    -- redirect to auth if user result is invalid not 200
    if res.status ~= 200 then
      error("Fetch user info failed", err)
    end
  else
    error("Internal error", err)
  end

  return cjson.decode(res.body)
end

function redirect_to_auth( conf, callback_url )
  -- Track the endpoint they wanted access to so we can transparently redirect them back
  kong.response.set_header("Set-Cookie", "EOAuthRedirectBack=" .. ngx.var.request_uri .. "; path=/;Max-Age=120")
  -- Redirect to the /oauth endpoint
  local oauth_authorize = conf.authorize_url .. "?response_type=code&client_id=" .. conf.client_id .. "&redirect_uri=" .. callback_url .. "&scope=" .. conf.scope
  return ngx.redirect(oauth_authorize)
end

function encode_token(token, conf)
  return ngx.encode_base64(crypto.encrypt("aes-128-cbc", token, crypto.digest('md5', conf.client_secret)))
end

function decode_token(token, conf)
  status, token = pcall(function () return crypto.decrypt("aes-128-cbc", ngx.decode_base64(token), crypto.digest('md5', conf.client_secret)) end)
  if status then
    return token
  else
    return nil
  end
end

-- Callback Handling
function handle_callback( conf, callback_url )
  local args = ngx.req.get_uri_args()

  if args.code then
    local httpc = http:new()
    local res, err = httpc:request_uri(conf.token_url, {
      method = "POST",
      ssl_verify = false,
      body = "grant_type=authorization_code&client_id=" .. conf.client_id .. "&client_secret=" .. conf.client_secret .. "&code=" .. args.code .. "&redirect_uri=" .. callback_url,
      headers = {
        ["Content-Type"] = "application/x-www-form-urlencoded",
        ["Accept"] = "application/json",
      }
    })

    if not res or res.status ~= 200 then
      kong.response.exit(ngx.HTTP_INTERNAL_SERVER_ERROR, {
        message = "Failed to request: " .. err
      })
    end

    local json = cjson.decode(res.body)
    local access_token = json.access_token
    if not access_token then
      kong.response.exit(ngx.HTTP_BAD_REQUEST, {
        message = "Failed get access token with json: " .. json
      })
    end

    kong.response.set_header("Set-Cookie", "EOAuthToken="..encode_token( access_token, conf ) .. "; path=/;Max-Age=" .. conf.auth_token_expire_time .. ";HttpOnly")
    -- Support redirection back to your request if necessary
    local redirect_back = ngx.var.cookie_EOAuthRedirectBack
    if redirect_back then
      return ngx.redirect(redirect_back)
    else
      return ngx.redirect(ngx.ctx.router_matches)
    end
  else
    kong.response.exit(ngx.HTTP_UNAUTHORIZED, {
      message = "User has denied access to the resources."
    })
  end
end

-- Builds a callback url taking into consideration any X-Forwarded headers
function get_callback_url(conf, path_prefix)
  if conf.callback_schema == nil then
    scheme = kong.request.get_forwarded_scheme()
    if scheme == nil or scheme == '' then
      scheme = kong.request.get_scheme()
    end
  else
    scheme = conf.callback_schema
  end

  if conf.callback_port == nil then
    port = kong.request.get_forwarded_port()
    if port == nil or port == '' then
      port = kong.request.get_port()
    end
  else
    port = conf.callback_port
  end

  local host = kong.request.get_forwarded_host();
  if not host then
    host = kong.request.get_host()
  end

  -- local port_uri = ":" .. port
  -- not support custom redirect port at this moment
  local port_uri = ""

  return scheme .. "://" .. host .. port_uri .. path_prefix .. "/oauth2/callback"
end

return _M
