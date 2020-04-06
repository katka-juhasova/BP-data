local BasePlugin = require "kong.plugins.base_plugin"
local responses = require "kong.tools.responses"
local strip = require("pl.stringx").strip
local tonumber = tonumber

local MB = 2^20
local PayloadSizeLimitingHandler = BasePlugin:extend()

PayloadSizeLimitingHandler.PRIORITY = 950

local function check_size(length, allowed_size, headers)
  local allowed_bytes_size = allowed_size * MB

  if length > allowed_bytes_size then
    if headers.expect and strip(headers.expect:lower()) == "100-continue" then
      return responses.send(417, "Payload size limit exceeded")
    else
      return responses.send(413, "Payload size limit exceeded")
    end
  end
end

function PayloadSizeLimitingHandler:new()
  PayloadSizeLimitingHandler.super.new(self, "payload-size-limiting")
end

function PayloadSizeLimitingHandler:access(conf)
  PayloadSizeLimitingHandler.super.access(self)
  local headers = ngx.req.get_headers()
  local cl = headers["content-length"]
  local ct = headers["content-type"]

  if not ct or ct == '' then
    ct = conf.default_content_type
  end

  if cl and tonumber(cl) then
    -- JSON
    if string.find(ct, 'json', 1, true) then
      check_size(tonumber(cl), conf.allowed_payload_size_json, headers)
    -- JavaScript
    elseif string.find(ct, 'javascript', 1, true) then
      check_size(tonumber(cl), conf.allowed_payload_size_javascript, headers)
    -- Text
    elseif string.find(ct, 'text', 1, true) then
      check_size(tonumber(cl), conf.allowed_payload_size_text, headers)
    -- Octet/other
    else
      check_size(tonumber(cl), conf.allowed_payload_size_octet, headers)
    end
  else
    ngx.req.read_body()
    local data = ngx.req.get_body_data()

    if data then
      -- JSON
      if string.find(ct, 'json', 1, true) then
        check_size(#data, conf.allowed_payload_size_json, headers)
      -- JavaScript
      elseif string.find(ct, 'javascript', 1, true) then
        check_size(#data, conf.allowed_payload_size_javascript, headers)
      -- Text
      elseif string.find(ct, 'text', 1, true) then
        check_size(#data, conf.allowed_payload_size_text, headers)
      -- Octet/other
      else
        check_size(#data, conf.allowed_payload_size_octet, headers)
      end
    end
  end
end

return PayloadSizeLimitingHandler
