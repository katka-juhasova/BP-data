local BasePlugin = require "kong.plugins.base_plugin"
local log = require "kong.cmd.utils.log"
local json = require "cjson"
local string = require "string"
local table = require "table"

local PipelineHandler = BasePlugin:extend()

local function split(s, sep)
    local start_index = 1
    local split_array = {}
    local sep_len = string.len(sep)
    if string.sub(sep, 1, 1) == "%" then
        sep_len = sep_len - 1
    end

    while true do
        local last_index = string.find(s, sep, start_index)
        if not last_index then
            split_array[#split_array+1] = string.sub(s, start_index, -1)
            break
        end
        split_array[#split_array+1] = string.sub(s, start_index, last_index - 1)
        start_index = last_index + sep_len
    end
    return split_array
end

function PipelineHandler:new()
    PipelineHandler.super.new(self, "pipeline")
end

function PipelineHandler:access(config)
    PipelineHandler.super.access(self)

    local ctx = ngx.ctx
    if ctx.balancer_address.type == "name" then
        local tag, _  = ngx.re.match(ngx.var.host, "[a-z]+([0-9]+)")
        if tag then
            local host_splited = split(ctx.balancer_address.host, "%.")
            host_splited[#host_splited-1] = (host_splited[#host_splited-1] or "") .. (tag[1] or "")
            ctx.balancer_address.host = table.concat(host_splited, ".")

            --ctx.api.upstream_url = (tag[1] or "") .. ctx.api.upstream_url
        end
    end
end

function PipelineHandler:header_filter(conf)
    PipelineHandler.super.header_filter(self)
end

return PipelineHandler

