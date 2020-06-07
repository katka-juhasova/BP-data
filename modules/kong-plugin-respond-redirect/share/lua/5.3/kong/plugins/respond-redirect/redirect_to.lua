-- local concat = table.concat

local ngx = ngx

local singletons = require "kong.singletons"
local constants = require "kong.constants"
local meta = require "kong.meta"

local kong = kong
local type = type
local find = string.find
local lower = string.lower
local match = string.match
local noop = function() end
local server_header = meta._SERVER_TOKENS

local _M = {}

function _M.replaceHeader(conf)
    kong.response.set_header("Content-Type", "text/html")
    local response_code = kong.response.get_status()
    local status  = conf.status_code
    local content = nil
    if response_code < 400 then

    else
        if response_code == 400 then
            content = conf.body_400
        elseif response_code == 401 then
            content = conf.body_401
        elseif response_code == 429 then
            content = conf.body_429
        elseif response_code >= 500 then
            content = conf.body_500
        else
            content = conf.body_xxx
            -- content = "<html><head><script>window.location.href=\"https://aoc.truecorp.co.th/K500.html\";</script></head><body></body></html>"
        end
        kong.response.set_header("Content-Length", string.len(content))
    end

end

function _M.replaceBody(conf)
    local response_code = kong.response.get_status()
    local status  = conf.status_code
    local content = nil
    if response_code < 400 then

    else
        if response_code == 400 then
            content = conf.body_400
        elseif response_code == 401 then
            content = conf.body_401
        elseif response_code == 429 then
            content = conf.body_429
        elseif response_code == 500 then
            content = conf.body_500
        else
            content = conf.body_xxx
            -- content = "<html><head><script>window.location.href=\"https://aoc.truecorp.co.th/K500.html\";</script></head><body></body></html>"
        end
    end
    return content;
end



function _M.redirect_to(conf)
    local response_code = kong.response.get_status()
    local status  = conf.status_code
    local content = nil
    if response_code == 400 then
        content = conf.body_400
    elseif response_code == 401 then
        content = conf.body_401
    elseif response_code == 429 then
        content = conf.body_429
    elseif response_code == 500 then
        content = conf.body_500
    end

    if content then
        local headers = {
        -- ["Content-Type"] = conf.content_type
            ["Content-Type"] = "text/html"
        }

        if singletons.configuration.enabled_headers[constants.HEADERS.SERVER] then
            headers[constants.HEADERS.SERVER] = server_header
        end

        return kong.response.exit(status, content, headers)
    end

    return kong.response.exit(status, { message = conf.message or DEFAULT_RESPONSE[status] })
  end

  return _M
