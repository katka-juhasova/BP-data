local BasePlugin = require "kong.plugins.base_plugin"
local responses = require "kong.tools.responses"
local strip = require("pl.stringx").strip

local RequestLimitValidatorHandler = BasePlugin:extend()

-- Making sure this plugin runs before "request-transformer"
-- leaving a little space so you could add another plugin in between
RequestLimitValidatorHandler.PRIORITY = 805
RequestLimitValidatorHandler.VERSION = "0.1.2"

function RequestLimitValidatorHandler:new()
  RequestLimitValidatorHandler.super.new(self, "request-size-limiting")
end

function countArgs(table)
  local cur = 0
  for k, v in pairs(table) do
    if type(v) == "table" then
      cur = cur + #v
    else
      cur = cur + 1
    end
  end
  return cur
end

function headerContains(header, checkValue)
  if type(header) == "string" then
    return header == checkValue
  elseif type(header) == "table" then
    for i, value in ipairs(header) do
      if value == checkValue then
        return true
      end
    end
  end

  return false
end

function RequestLimitValidatorHandler:access(conf)
  RequestLimitValidatorHandler.super.access(self)
  local args, _ = ngx.req.get_uri_args(conf.allowed_number_query_args + 1)
  local expect100continue = false
  local headers = ngx.req.get_headers()

  if headers.expect and strip(headers.expect:lower()) == "100-continue" then
    expect100continue = true
  end

  if countArgs(args) > conf.allowed_number_query_args  then
    -- 414 is url too long
    responses.send((expect100continue and 417 or 414), "request-limit-validator: Too many querystring parameters!")
  end

  if headerContains(headers["content-type"], "application/x-www-form-urlencoded") then
    ngx.req.read_body()
    local args, _ = ngx.req.get_post_args(conf.allowed_number_post_args + 1)

    if countArgs(args) > conf.allowed_number_post_args  then
      -- 413 is payload too large
      responses.send((expect100continue and 417 or 413), "request-limit-validator: Too many post parameters!")
    end
  end
end

return RequestLimitValidatorHandler
