local Statsd = require "statsd"

local statsd = Statsd({
  host = config.host or "127.0.0.1",
  port = config.port or 8125,
  namespace = config.namespace or ""
})

context.statsd = statsd

