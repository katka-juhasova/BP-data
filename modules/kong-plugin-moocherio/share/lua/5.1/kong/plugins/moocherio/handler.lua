local shcache = require "resty.shcache"
local http    = require "resty.http"
local responses = require "kong.tools.responses"

local BasePlugin = require "kong.plugins.base_plugin"

local MoocherIoHandler = BasePlugin:extend()

MoocherIoHandler.PRIORITY = 2000

function MoocherIoHandler:new()
  MoocherIoHandler.super.new(self, "moocherio")
end

function MoocherIoHandler:access(conf)
  MoocherIoHandler.super.access(self)

    local moocher_url  = conf.moocherio_endpoint
    local cache_ttl    = conf.cache_entry_ttl
    local x_auth_token = conf.moocherio_api_key

    local all_headers = {}

    if x_auth_token then
        all_headers = { ["X-Auth-Token"] = x_auth_token }
    end

    local function load_from_cache(key)

        -- closure to perform external lookup to moocher.io services
        local lookup = function ()

            local httpc = http.new()
                  local res, err = httpc:request_uri(moocher_url .. key,  {
                    method = "GET",
                    ssl_verify = false,
                    headers = all_headers
                  })

            -- Something went wrong...
            if not res then
              ngx.say("failed to request: ", err)
              return nil, err
            end

            local status = tonumber(res.status)

            ngx.log(ngx.DEBUG, status)

            if status == 200 then
              return 200, nil
            else
              return nil, nil
            end
        end

        local moocherio_table = shcache:new(
            ngx.shared.cache_dict,
            { external_lookup = lookup
            },
            { positive_ttl = cache_ttl,            -- cache good data for cache_ttl
              negative_ttl = cache_ttl,            -- cache failed lookup for cache_ttl
              actualize_ttl = 1,                   -- do not cache updates
              name = 'moocherio',                  -- "named" cache, useful for debug / report
            }
        )

        local from_local, from_remote = moocherio_table:load(key)

        if from_local then
            if from_remote then
                -- cache_status == "HIT" (or "STALE")
                ngx.log(ngx.DEBUG, "Data at local for sure. CACHE HIT")
                return responses.send_HTTP_FORBIDDEN("Your IP address is not allowed")
            else
                -- cache_status == "MISS"
                ngx.log(ngx.DEBUG, "No data at local but there is at remote. CACHE MISS (valid data)")
                return responses.send_HTTP_FORBIDDEN("Your IP address is not allowed")
            end
        else
            if from_remote then
                -- cache_status == "HIT_NEGATIVE"
                ngx.log(ngx.DEBUG, "Negative data at local and I don't know at remote. CACHE HIT NEGATIVE")
            else
                -- cache_status == "NO_DATA"
                ngx.log(ngx.DEBUG, "No data at local and there is at remote. CACHE MISS (bad data)")
            end
        end

    end

    local ip = ngx.var.remote_addr
    load_from_cache(ip)

end

return MoocherIoHandler
