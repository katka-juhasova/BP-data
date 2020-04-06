local BasePlugin       = require "kong.plugins.base_plugin"
local basic_serializer = require "kong.plugins.log-serializers.basic"
local statsd_logger    = require "kong.plugins.datadog.statsd_logger"
local tablex           = require "pl.tablex"


local ngx_log       = ngx.log
local ngx_timer_at  = ngx.timer.at
local string_gsub   = string.gsub
local pairs         = pairs
local string_format = string.format
local NGX_ERR       = ngx.ERR


local DatadogHandler    = BasePlugin:extend()
DatadogHandler.PRIORITY = 10
DatadogHandler.VERSION = "0.2.1"


local get_consumer_id = {
  consumer_id = function(consumer)
    return consumer and string_gsub(consumer.id, "-", "_")
  end,
  custom_id   = function(consumer)
    return consumer and consumer.custom_id
  end,
  username    = function(consumer)
    return consumer and consumer.username
  end
}

local function safe_merge(table_or_nil, table_to_add)
  local new_table = {}
  if table_or_nil ~= nil then
    for _, v in pairs(table_or_nil) do
      table.insert(new_table, v)
    end
  end

  if table_to_add ~= nil then
    for _, v in pairs(table_to_add) do
      table.insert(new_table, v)
    end
  end

  return new_table
end

local function append(table_or_nil, new_element)
  return safe_merge(table_or_nil, {new_element})
end

local function increment_status(fmt, status, tags, sample_rate, logger)
  local tags = append(tags, string_format("%s:%s", "status", status))
  logger:send_statsd(
    fmt, 1, logger.stat_types.counter, sample_rate, tags
  )
end

local metrics = {
  status_count = function (message, tags, metric_config, logger)
    local fmt = "request.status"
    increment_status(fmt, message.response.status, tags, metric_config.sample_rate, logger)

    logger:send_statsd(string_format("%s.%s", fmt, "total"), 1,
                       logger.stat_types.counter,
                       metric_config.sample_rate, tags)
  end,
  unique_users = function (message, tags, metric_config, logger)
    local get_consumer_id = get_consumer_id[metric_config.consumer_identifier]
    local consumer_id     = get_consumer_id(message.consumer)

    if consumer_id then
      local stat = "user.uniques"

      logger:send_statsd(stat, consumer_id, logger.stat_types.set,
                         nil, tags)
    end
  end,
  request_per_user = function (message, tags, metric_config, logger)
    local get_consumer_id = get_consumer_id[metric_config.consumer_identifier]
    local consumer_id     = get_consumer_id(message.consumer)

    if consumer_id then
      local stat = string_format("user.%s.request.count", consumer_id)

      logger:send_statsd(stat, 1, logger.stat_types.counter,
                         metric_config.sample_rate, tags)
    end
  end,
  status_count_per_user = function (message, tags, metric_config, logger)
    local get_consumer_id = get_consumer_id[metric_config.consumer_identifier]
    local consumer_id     = get_consumer_id(message.consumer)

    if consumer_id then
      local fmt = string_format("user.%s.request.status", consumer_id)

      increment_status(fmt, message.response.status, tags, metric_config.sample_rate, logger)

      logger:send_statsd(string_format("%s.%s", fmt,  "total"),
                         1, logger.stat_types.counter,
                         metric_config.sample_rate, tags)
    end
  end,
}

local function log(premature, conf, message)
  if premature then
    return
  end

  local stat_name  = {
    request_size     = "request.size",
    response_size    = "response.size",
    latency          = "latency",
    upstream_latency = "upstream_latency",
    kong_latency     = "kong_latency",
    request_count    = "request.count",
  }
  local stat_value = {
    request_size     = message.request.size,
    response_size    = message.response.size,
    latency          = message.latencies.request,
    upstream_latency = message.latencies.proxy,
    kong_latency     = message.latencies.kong,
    request_count    = 1,
  }

  local logger, err = statsd_logger:new(conf)
  if err then
    ngx_log(NGX_ERR, "failed to create Statsd logger: ", err)
    return
  end

  local request_tags = {string_format("%s:%s", "api_name", message.api.name)}
  if message.api.uris ~= nil then
    request_tags = append(
      request_tags,
      string_format("%s:%s", "api_uris", table.concat(message.api.uris, ","))
    )
  end

  for _, metric_config in pairs(conf.metrics) do
    local metric = metrics[metric_config.name]
    local tags = safe_merge(metric_config.tags, request_tags)

    if metric then
      metric(message, tags, metric_config, logger)

    else
      local stat_name  = stat_name[metric_config.name]
      local stat_value = stat_value[metric_config.name]

      logger:send_statsd(stat_name, stat_value,
                         logger.stat_types[metric_config.stat_type],
                         metric_config.sample_rate, tags)
    end
  end

  logger:close_socket()
end

function get_env_var(key)
  local env_name = "KONG_" .. string.upper(key)
  return os.getenv(env_name)
end

function DatadogHandler:new()
  DatadogHandler.super.new(self, "datadog-tags")
  -- Environment variables are not available later (nginx clears env vars for the worker processes)
  self.env_overrides = {
    host       = get_env_var("dd_agent_host"),
    port       = get_env_var("dd_agent_port"),
    prefix     = get_env_var("dd_prefix")
  }
end

function DatadogHandler:log(conf)
  DatadogHandler.super.log(self)

  -- unmatched apis are nil
  if not ngx.ctx.api then
    return
  end

  local message = basic_serializer.serialize(ngx)

  local perform_union = true
  local conf_with_overrides = tablex.merge(conf, self.env_overrides, perform_union)

  local ok, err = ngx_timer_at(0, log, conf_with_overrides, message)
  if not ok then
    ngx_log(NGX_ERR, "failed to create timer: ", err)
  end
end

return DatadogHandler
