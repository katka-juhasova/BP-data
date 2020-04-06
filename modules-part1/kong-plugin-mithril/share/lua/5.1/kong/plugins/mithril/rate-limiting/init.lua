local policy = require "kong.plugins.mithril.rate-limiting.policy"
local timestamp = require "kong.tools.timestamp"
local resty_md5 = require "resty.md5"
local str = require "resty.string"

local ngx_log = ngx.log
local pairs = pairs
local tostring = tostring
local ngx_timer_at = ngx.timer.at

local RATELIMIT_LIMIT = "X-RateLimit-Limit"
local RATELIMIT_REMAINING = "X-RateLimit-Remaining"

local function get_usage(conf, route_id, identifier, current_timestamp, limits)
  local usage = {}
  local stop

  for name, limit in pairs(limits) do
    local current_usage, err = policy.usage(conf, route_id, identifier, current_timestamp, name)
    if err then
      return nil, nil, err
    end

    -- What is the current usage for the configured limit name?
    local remaining = limit - current_usage

    -- Recording usage
    usage[name] = {
      limit = limit,
      remaining = remaining
    }

    if remaining <= 0 then
      stop = name
    end
  end

  return usage, stop
end

return {
  verify = function(conf, token)
    local current_timestamp = timestamp.get_utc()
    local md5 = resty_md5:new()
    md5:update(token)
    local identifier = str.to_hex(md5:final())
    local route_id = ngx.ctx.route.id
    local fault_tolerant = conf.fault_tolerant

    -- Load current metric for configured period
    local limits = {
      second = conf.second,
      minute = conf.minute,
      hour = conf.hour,
      day = conf.day,
      month = conf.month,
      year = conf.year
    }

    local ordered_periods = {"second", "minute", "hour", "day", "month", "year"}
    local has_value

    for i, v in ipairs(ordered_periods) do
      if conf[v] then
        has_value = true
      end
    end

    if not has_value then
      return true
    end

    local usage, stop, err = get_usage(conf, route_id, identifier, current_timestamp, limits)
    if err then
      if fault_tolerant then
        ngx_log(ngx.ERR, "failed to get usage: ", tostring(err))
      else
        return kong.response.exit(500, err)
      end
    end

    if usage then
      -- Adding headers
      if not conf.hide_client_headers then
        for k, v in pairs(usage) do
          ngx.header[RATELIMIT_LIMIT .. "-" .. k] = v.limit
          ngx.header[RATELIMIT_REMAINING .. "-" .. k] =
            math.max(0, (stop == nil or stop == k) and v.remaining - 1 or v.remaining) -- -increment_value for this current request
        end
      end

      -- If limit is exceeded, terminate the request
      if stop then
        return kong.response.exit(429, "API rate limit exceeded")
      end
    end

    local incr = function(premature, conf, limits, route_id, identifier, current_timestamp, value)
      if premature then
        return
      end
      policy.increment(conf, limits, route_id, identifier, current_timestamp, value)
    end

    -- Increment metrics for configured periods if the request goes through
    local ok, err = ngx_timer_at(0, incr, conf, limits, route_id, identifier, current_timestamp, 1)
    if not ok then
      ngx_log(ngx.ERR, "failed to create timer: ", err)
    end
  end
}
